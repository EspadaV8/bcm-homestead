class Homestead
  def Homestead.configure(config, settings)
    # The url from where the 'config.vm.box' box will be fetched if it
    # doesn't already exist on the user's system.
    config.vm.box = "Espadav8/dws-7"
    config.vm.hostname = settings["hostname"]

    # Configure A Private Network IP
    config.vm.network :private_network, ip: settings["ip"] ||= "192.168.10.10"

    # Configure A Few VirtualBox Settings
    config.vm.provider "virtualbox" do |vb|
      vb.name = 'homestead'
      vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
      vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy2", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver2", "on"]
    end

    # Configure Port Forwarding To The Box
    config.vm.network "forwarded_port", guest: 80, host: 8080
    config.vm.network "forwarded_port", guest: 443, host: 44300
    config.vm.network "forwarded_port", guest: 3306, host: 33060
    config.vm.network "forwarded_port", guest: 5432, host: 54320

    # Configure The Public Key For SSH Access
    config.vm.provision "shell" do |s|
      s.inline = "echo $1 | tee -a /home/vagrant/.ssh/authorized_keys"
      s.args = [File.read(File.expand_path(settings["authorize"]))]
    end

    # Copy The SSH Private Keys To The Box
    settings["keys"].each do |key|
      config.vm.provision "shell" do |s|
        s.privileged = false
        s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
        s.args = [File.read(File.expand_path(key)), key.split('/').last]
      end
    end

    # Copy The Bash Aliases
    config.vm.provision "shell" do |s|
      s.inline = "cp /vagrant/aliases /home/vagrant/.bash_aliases"
    end

    # Delete existing nginx sites
    config.vm.provision "shell" do |s|
      s.inline = "rm -rf /etc/nginx/sites-enabled/*"
    end

    # Delete existing apache2 sites
    config.vm.provision "shell" do |s|
      s.inline = "rm -rf /etc/apache2/sites-enabled/*"
    end

    # Register All Of The Configured Shared Folders
    settings["folders"].each do |folder|
      config.vm.synced_folder folder["map"], folder["to"], type: folder["type"] ||= nil
    end

    # Install All The Configured Nginx Sites
    settings["sites"].each do |site|
      config.vm.provision "shell" do |s|
          if (site.has_key?("hhvm") && site["hhvm"])
            s.inline = "bash /vagrant/scripts/serve-hhvm.sh $1 $2"
            s.args = [site["map"], site["to"]]
          else
            s.inline = "bash /vagrant/scripts/serve.sh $1 $2 $3"
            s.args = [site["map"], site["to"], site["logs"]]
          end
      end
    end

    # Configure All Of The Configured Databases
    if settings.has_key?("databases")
        settings["databases"].each do |db|
            config.vm.provision "shell" do |s|
                s.path = "./scripts/create-mysql.sh"
                s.args = [db, settings["db_username"], settings["db_password"]]
            end

            # config.vm.provision "shell" do |s|
            #     s.path = "./scripts/create-postgres.sh"
            #     s.args = [db, settings["db_username"], settings["db_password"]]
            # end
        end
    end

    # Configure All Of The Server Environment Variables
    if settings.has_key?("variables")
      settings["variables"].each do |var|
        config.vm.provision "shell" do |s|
            s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php5/fpm/php-fpm.conf && service php5-fpm restart"
            s.args = [var["key"], var["value"]]
        end
      end
    end

    # Update Composer On Every Provision
    config.vm.provision "shell" do |s|
      s.inline = "/usr/local/bin/composer self-update"
    end

    config.vm.provision "shell", run: "always" do |s|
      s.inline = "bash /vagrant/scripts/restart-web-servers.sh"
    end
  end
end
