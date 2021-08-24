#!/usr/bin/env python3
from tenable.base.platform import APIPlatform
from subprocess import Popen
from pathlib import Path
from time import sleep
import requests
import logging
import urllib3
import pexpect
import typer
import yaml


urllib3.disable_warnings()
app = typer.Typer()


class Nessus(APIPlatform):
    _env_base = 'NESSUS'
    _port = 8834
    _address = 'localhost'
    _ssl_verify = False

    def _authenticate(self, **kwargs):
        def session_auth():
            resp = self.post('session', json={
                'username': self._auth[0],
                'password': self._auth[1]
            })
            self._session.headers.update({
                'X-Cookie': f'token={resp.token}'
            })
            self._auth_mech = 'user'
        kwargs['session_auth_func'] = session_auth
        super()._authenticate(**kwargs)


@app.command()
def adduser(username: str, password: str):
    '''
    Simple non-interactive admin user creation func.
    '''
    p = pexpect.spawn(f'/opt/nessus/sbin/nessuscli adduser {username}')
    p.expect('Login password')
    p.sendline(password)
    p.expect('Login password')
    p.sendline(password)
    p.expect('system administrator')
    p.sendline('y')
    p.expect('empty rules set')
    p.sendline('')
    p.expect('system administrator')
    p.sendline('y')
    p.wait()


@app.command()
def spawn(terminate: bool = False) -> Popen:
    '''
    Spawns and waits for Nessus to become available.
    '''
    # launch Nessus
    p = Popen(['/opt/nessus/sbin/nessus-service'])

    # Wait for Nessus to become ready
    loaded = False
    while not loaded:
        sleep(10)
        try:
            r = requests.get('https://localhost:8834/server/status',
                             verify=False).json()
            if r['status'] == 'ready':
                loaded = True
            elif r['status'] == 'loading':
                logging.debug((f'Nessus plugin loading is '
                               f'{r.get("progress", 0)}% complete'))
        except Exception:
            pass
    if terminate:
        p.terminate()
    return p


@app.command()
def scan(hosts: str,
         ssh_key: Path = typer.Option('/creds/key',
                                      help=('The SSH private keyfile.  This '
                                            'file must be in a PEM format.')),
         ssh_key_pw: str = typer.Option('',
                                        help='The passphrase to the SSH Key'),
         username: str = typer.Option('root',
                                      help=('The username of the remote host '
                                            'that the authenticated scan will '
                                            'be performed using')),
         priv_escalation: str = typer.Option('Nothing',
                                             help=('The type of privilege '
                                                   'escalation to be '
                                                   'performed.  Typically '
                                                   '"sudo" is used when a '
                                                   'non-root account is used.')
                                             ),
         escalation_account: str = typer.Option('root',
                                                help=('The account that the '
                                                      'scanner will attempt '
                                                      'to escalate to.'))
         ):
    '''
    Scan the hosts with ssh key
    '''
    logging.basicConfig(level=logging.DEBUG)
    p = spawn()

    creds = yaml.safe_load(open('/etc/nessus_creds.yaml'))
    scanner = Nessus(username=creds.get('username'),
                     password=creds.get('password'))

    # Get the Template UUID for the Advanced scan profile.
    template_id = 'ad629e16-03b6-8c1d-cef6-ef8c9dd3c658d24bd260ef5f9e66'
    for tmpl in scanner.get('editor/scan/templates').templates:
        if tmpl.name == 'advanced':
            template_id = tmpl.uuid

    # Upload SSH Credentials
    fn = scanner.post('file/upload', files={'Filedata': open(ssh_key, 'rb')})
    keyname = fn.fileuploaded

    # Launch the scan
    scan = scanner.post('scans', json={
        "uuid": template_id,
        "settings": {
            "test_local_nessus_host": "no",
            "launch_now": True,
            "enabled": False,
            "live_results": "",
            "name": "Auto-launched Scan",
            "description": "",
            "folder_id": 3,
            "scanner_id": "1",
            "text_targets": hosts,
            "file_targets": ""
        },
        "credentials": {
            "add": {
                "Host": {
                    "SSH": [
                        {
                            "auth_method": "public key",
                            "username": username,
                            "private_key": keyname,
                            "private_key_passphrase": ssh_key_pw,
                            "elevate_privileges_with": priv_escalation,
                            "escalation_account": escalation_account
                        }
                    ]
                }
            },
        }
    })

    # Wait for the scan to complete
    info = scanner.get(f'scans/{scan.scan.id}')
    while info.info.status[-3:] == 'ing':
        sleep(60)
        info = scanner.get(f'scans/{scan.scan.id}')

    # Download the report
    with open('/scan/report.xml', 'wb') as fobj:
        # initiate the export
        fid = scanner.post(f'scans/{scan.scan.id}/export', json={
            'format': 'nessus',
            'chapters': 'vuln_by_host',
        }).file

        # wait for the export to be available
        dl = f'scans/{scan.scan.id}/export/{fid}'
        while scanner.get(f'{dl}/status').status not in ['error', 'ready']:
            sleep(1)

        # write the report to the file.
        resp = scanner.get(f'{dl}/download', stream=True)
        for chunk in resp.iter_content(chunk_size=1024):
            if chunk:
                fobj.write(chunk)

    # Kill the Nessus daemon
    p.terminate()


if __name__ == '__main__':
    app()
