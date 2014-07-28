default[:activemq] = {
  :cluster_name => 'default',
  :user         => 'activemq',
  :group        => 'activemq',
  :user_home    => nil,
  :setup_user   => false,
  :version      => '5.10.0',
  :install_dir  => '/usr/local/activemq',
  :data_dir     => '/opt/activemq',
  :notify_restart   => false, # notify service restart on config change
  :service_name     => 'activemq',
  :dir_mode     => '0755', # default directory permissions used by activemq cookbook
  :pid_dir      => '/var/run/activemq', # solr service user pid dir
  :log_dir      => '/var/log/activemq',
  :templates_cookbook => "activemq", # template source cookbook

  :limits => {
    :memlock    => 'unlimited',
    :nofile     => 48000,
    :nproc      => 'unlimited'
  },

  :log4j        => {
    :max_file_size    => '10MB',
    :max_backup_index => '10'
  },

  :wrapper      => {
    :init_memory  => 512,
    :maxmemory    => 1024, # This needs to be RAM dependent
  },

  :stomp        => {
    :enable     => true,
    :port       => 61613
  },
  :amqp         => {
    :enable     => true,
    :port       => 5672
  },
  :openwire     => {
    :enable     => true,
    :port       => 61616
  },
  :mqtt         => {
    :enable     => true,
    :port       => 1883
  },
  :ws           => {
    :enable     => true,
    :port       => 61614
  },
  :config       => {
    :enable_management  => 'true',
    :maxconns               => 10000,
    :maxframesize           => 104857600,
    :listen_address         => '0.0.0.0',
    :pending_message_limit  => '1000'
  }
}

default[:activemq][:source_dir]      = "/usr/local/apache-activemq-#{node.activemq.version}"
default[:activemq][:tarball][:url]   = "https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-activemq/#{node.activemq.version}/apache-activemq-#{node.activemq.version}-bin.tar.gz"
default[:activemq][:tarball][:md5]   = 'bb83016ae899e0c8a346ffeee15a0390'


