# raar_show_descriptor

Store missing show descriptions from the rabe.ch website into archiv.rabe.ch.

See configuration in `config/settings.example.yml`. Copy this file to `config/settings.yml`, complete it and run `bin/raar_show_descriptor.rb`.

This script is meant to be run manually, because new show descriptions are not added that often.


## Deployment

## Initial

* Install dependencies: `yum install gcc gcc-c++ glibc-headers rh-ruby25-ruby-devel rh-ruby25-rubygem-bundler libxml2-devel libxslt-devel`
* Create a user on the server:
  * `useradd --home-dir /opt/raar-scripts --create-home --user-group raar-scripts`
  * `usermod -a -G raar-scripts <your-ssh-user>`
  * Add your SSH public key to `/opt/raar-scripts/.ssh/authorized_keys`.
* Perform the every time steps.
* Copy `settings.example.yml` to `settings.yml` and add the missing credentials.
* Copy both systemd files from `config` to `/etc/systemd/system/`.
* Enable and start the systemd timer: `systemctl enable --now raar-show-descriptor.timer`

## Every time

* Prepare the dependencies on your local machine: `bundle package --all-platforms`
* SCP or Rsync all files: `rsync -avz --exclude .git --exclude .bundle --exclude config/settings.yml . raar-scripts@[server]:/opt/raar-show-descriptor/`.
* Install the dependencies on the server (as `raar-scripts` in `/opt/raar-show-descriptor`):
  `source /opt/rh/rh-ruby25/enable && bundle install --deployment --local`


## License

raar_show_descriptor is released under the terms of the GNU Affero General Public License.
Copyright 2019-2021 Radio RaBe.
See `LICENSE` for further information.
