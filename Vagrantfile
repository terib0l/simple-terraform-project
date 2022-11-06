Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2004"
  config.vm.synced_folder "./tf", "/home/vagrant/tf"

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf ./aws && rm awscliv2.zip
    aws --version

    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update && apt-get install terraform
    terraform --version
  SHELL
end
