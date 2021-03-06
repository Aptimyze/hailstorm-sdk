# Introduction
``hailstorm-gem`` is the core Hailstorm library and CLI of the Hailstorm application suite.

# User Guide
Refer to the [Hailstorm Wiki](https://github.com/3pillarlabs/hailstorm-sdk/wiki) for the user guide.

# Developer Guide
Use the User Guide to setup your own Hailstorm virtual machine. Once this is done, create a development environment
in the virtual machine. SSH to the VM and -
```bash
cd /vagrant/hailstorm-gem
rvm gemset create hailstorm-dev
rvm use @hailstorm-dev
gem install --no-rdoc --no-ri bundler
bundle install
```

## Database User
Create a MySQL user ``hailstorm_dev``:
```bash
mysql -uroot <<< 'grant all privileges on *.* to "hailstorm_dev"@"localhost" identified by "hailstorm_dev"'
```

You are all set.

## Unit tests (specs)
```bash
rspec
```

## Integration tests
This requires an AWS account and a little more setup. Ensure your AWS account has a VPC with a public subnet.

### AWS tests

```bash
cp features/data/keys-sample.yml features/data/keys.yml
```

Edit ``features/data/keys-sample.yml`` to add your AWS access and secret keys.

### Data Center tests
To execute the data-center integration tests, two nodes need to be setup.

**Note** - The ``resources/data-center/Dockerfile`` can also be used to build Docker images to run on data-center machines.
This is a considerably easier process to ensure that the nodes in the data center are setup correctly to work with
Hailstorm. However, note that the Docker container enables SSH using an insecure key, it is essential that the SSH port
be protected from access outside the data-center.

### Linux
For Linux, use the Docker containers.

#### Build an image
```bash
cd resources/data-center
docker build -t hailstorm-data-center-node:latest .
```

#### Run the container and daemonize
```bash
docker run -it --rm --name hs-dc-node-1 -d hailstorm-data-center-node:latest
docker run -it --rm --name hs-dc-node-2 -d hailstorm-data-center-node:latest
```

To find the IP addresses -
```bash
for ctr in $(docker ps | cut -f1 -d' ' | grep -v CONTAINER); do \
  docker inspect -f '{{ .NetworkSettings.IPAddress }}' $ctr; \
done
```

### MacOS

For MacOs, use the VirtualBox VMs using Vagrant.
```bash
vagrant up hs-dc-vm-1
vagrant up hs-dc-vm-2
```
The IP addresses are ``192.168.27.10`` and ``192.168.27.20``.


### Configuration
Once the setup is done, copy ``features/data/data-center-machines-sample.yml`` to
``features/data/data-center-machines.yml`` and add the IP addresses of the Docker containers or Vagrant VMs based on the
setup.

### Bring up the target sites

Copy ``setup/hailstorm-site/vagrant-site-sample.yml`` to ``setup/hailstorm-site/vagrant-site.yml`` and edit the
properties.

```bash
vagrant up site
vagrant up site-local
```

### Execution
```bash
# Important commands and options
cucumber --tag @smoke

# Common scenarios
cucumber --tag @end-to-end

# All scenarios
cucumber
```

# Version 5
```ruby
middleware = Hailstorm::Support::Initializer.create_middleware('hailstorm_spec', '/path/to/project/config/boot.rb')
expect(middleware).to respond_to(:interpretor)

cli = Hailstorm::Controller::Cli.new(middleware)
cli.process_commands

webs = Hailstorm::Controller::WebServer.new(middleware)
webs.start_server
```
