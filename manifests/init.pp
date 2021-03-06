# Basic SSH module
#
# Ensure sshd is running everywhere
# Also generates hostkeys on demand on the puppetmaster so that rebuilding
# a host doesn't cause MITM warnings
#
class ssh {

  $package = $::osfamily ? {
    "Archlinux" => "openssh",
    default     => "openssh-server",
  }
  $service_name =  $::osfamily ? {
    "Archlinux" => 'sshd.service',  # systemd workaround
    "RedHat"    => 'sshd',
    default     => 'ssh',
  }

  package { $package: ensure => installed }
  ~>
  file { '/etc/ssh/sshd_config':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('ssh/sshd.conf.erb')
  }
  ~>
  service { 'ssh':
    ensure     => running,
    name       => $service_name,
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
  }

  # Generate RSA keys reliably
  $rsa_priv = ssh_keygen({name => "ssh_host_rsa_${::fqdn}", dir => 'ssh/hostkeys'}) 
  $rsa_pub  = ssh_keygen({name => "ssh_host_rsa_${::fqdn}", dir => 'ssh/hostkeys', public => 'true'}) 

  file { '/etc/ssh/ssh_host_rsa_key':
    owner   => 'root',
    group   => 'root',
    mode    => 0600,
    content => $rsa_priv,
    notify  => Service['ssh'],
  }

  file { '/etc/ssh/ssh_host_rsa_key.pub':
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    content => "ssh-rsa $rsa_priv host_rsa_${::hostname}\n",
    notify  => Service['ssh'],
  }

}
