# REC Clocks Init Scripts

This document provides instructions for setting up and managing the systemd service for the REC Clocks display scripts.

## Copying and Installing the Service File

To install the systemd service for the clock display, copy the `rec-clocks.service` file to `/etc/systemd/system/`:

```bash
sudo cp rec-clocks.service /etc/systemd/system/
```

Then, enable and start the service:

```bash
sudo systemctl enable rec-clocks
sudo systemctl start rec-clocks
```

## Checking the Service Status

To check if the service is running correctly, use:

```bash
sudo systemctl status rec-clocks
```

## Stopping the Service

To stop the service, use:

```bash
sudo systemctl stop rec-clocks
```

## Restarting the Service

If you make changes to the script or configuration, reload and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart rec-clocks
```

## Switching Between Scripts

The service is configured to run `screen16-32-simp_gmt.py` by default. To switch to a different script, edit the service file:

```bash
sudo nano /etc/systemd/system/rec-clocks.service
```

Modify the `ExecStart` line to use the desired script. For example:

- To use `screen16-32-simp.py`:
  ```ini
  ExecStart=/usr/bin/python3 /home/riley/git/rec-clocks/screen16-32-simp.py
  ```
- To use `screen16-32-temp.py`:
  ```ini
  ExecStart=/usr/bin/python3 /home/riley/git/rec-clocks/screen16-32-temp.py
  ```

After making changes, save the file and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart rec-clocks
```

## License
This project is open-source and licensed under the GNU General Public License v3.0 (GPLv3). See the LICENSE file for more details.


