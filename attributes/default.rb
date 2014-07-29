default[:activemq] = {
  :cluster_name => 'default', # reserved attribute for future use with Chef Node Discovery
  :user         => 'activemq',
  :group        => 'activemq',
  :user_home    => nil,
  :setup_user   => false, # manage user account
  :version      => '5.10.0',
  :install_dir  => '/usr/local/activemq',
  :data_dir     => '/opt/activemq',
  :notify_restart   => false, # notify service restart on config change
  :service_name     => 'activemq',
  :dir_mode     => '0755', # default directory permissions used by activemq cookbook
  :pid_dir      => '/var/run/activemq', # solr service user pid dir
  :log_dir      => '/var/log/activemq',
  :templates_cookbook => "activemq", # template source cookbook
  :auto_maxmemory     => true, # automatically calculate maximum memory 
  :system_memory      => 768, # minimum reserved memory for the system, required when set :auto_maxmemory => true

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
    :init_memory  => 512
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
    :enable_management      => 'true',
    :maxconns               => 10000,
    :maxframesize           => 104857600,
    :listen_address         => '0.0.0.0',
    :pending_message_limit  => '10000'
  }
}

default[:activemq][:source_dir]      = "/usr/local/apache-activemq-#{node.activemq.version}"
default[:activemq][:tarball][:url]   = "https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-activemq/#{node.activemq.version}/apache-activemq-#{node.activemq.version}-bin.tar.gz"
default[:activemq][:tarball][:md5]   = 'bb83016ae899e0c8a346ffeee15a0390'

if not node.activemq.auto_maxmemory
  default[:activemq][:wrapper][:maxmemory]   = 1024
else
  # Calculate Java Xmx memory value
  if node.memory and node.memory.has_key?('total')
    total_memory    = node.memory.total.gsub('kB','').to_i / 1024
    mem_per         = (total_memory.to_i % 1024)
    system_memory   = if total_memory.to_i < 2048
                        total_memory.to_i / 2
                      else
                        if mem_per >= node.activemq.system_memory.to_i
                          mem_per
                        else
                          mem_per + 1024
                        end
                      end
    java_memory     = total_memory.to_i - system_memory
    # Covers total_memory / 2 condition, Always Keeping Java -Xmx even integer
    java_memory     += 1 if not java_memory.even?
    default[:activemq][:wrapper][:maxmemory] = java_memory
  end
end

