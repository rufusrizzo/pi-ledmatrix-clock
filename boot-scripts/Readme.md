# pi-ledmatrix-clock Init Scripts

This document provides instructions for setting up and managing the systemd service for the pi-ledmatrix-clock display scripts.

## Copying and Installing the Service File

Update your Username and replace "riley" with your user, and the file path to the location of the git repo.

To install the systemd service for the clock display, copy the `pi-ledmatrix-clock.service` file to `/etc/systemd/system/`:

```bash
sudo cp pi-ledmatrix-clock.service /etc/systemd/system/
```

Then, enable and start the service:

```bash
sudo systemctl enable pi-ledmatrix-clock
sudo systemctl start pi-ledmatrix-clock
```

## Checking the Service Status

To check if the service is running correctly, use:

```bash
sudo systemctl status pi-ledmatrix-clock
```

## Stopping the Service

To stop the service, use:

```bash
sudo systemctl stop pi-ledmatrix-clock
```

## Restarting the Service

If you make changes to the script or configuration, reload and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart pi-ledmatrix-clock
```

## Switching Between Scripts

The service is configured to run `screen16-32-simp_gmt.py` by default. To switch to a different script, edit the service file:

```bash
sudo nano /etc/systemd/system/pi-ledmatrix-clock.service
```

Modify the `ExecStart` line to use the desired script. For example:

- To use `screen16-32-simp.py`:
  ```ini
  ExecStart=/usr/bin/python3 /home/riley/git/pi-ledmatrix-clock/screen16-32-simp.py
  ```
- To use `screen16-32-temp.py`:
  ```ini
  ExecStart=/usr/bin/python3 /home/riley/git/pi-ledmatrix-clock/screen16-32-temp.py
  ```

After making changes, save the file and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart pi-ledmatrix-clock
```

## License
This project is open-source and licensed under the GNU General Public License v3.0 (GPLv3). See the LICENSE file for more details.


