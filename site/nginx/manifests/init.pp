class nginx {

notify {"Platform OS is: ${facts['os']['family']}":}

case $facts['os']['family'] {

'redhat','debian' : {
$package = 'nginx'
$owner = 'root'
$group = 'root'
$docroot = '/var/www'
$confdir = '/etc/nginx'
$logdir = '/var/log/nginx'
$run_pid_path = '/var/run'
}

'windows' : {
$package = 'nginx-service'
$owner = 'Administrator'
$group = 'Administrators'
$docroot = 'C:/ProgramData/nginx/html'
$confdir = 'C:/ProgramData/nginx'
$logdir = 'C:/ProgramData/nginx/logs'
$run_pid_path = 'C:/ProgramData/nginx/run'
}

default : {
  fail("Module ${module_name} is not supported on ${facts['os']['family']}")
}

}

#user the service will run as. Used in the nginx.conf.epp template
$user = $facts['os']['family'] ? {
'redhat' => 'nginx',
'debian' => 'www-data',
'windows' => 'nobody',
} 

File {
owner => $owner,
group => $group,
mode => '0664',
} 

package { $package:
ensure => present,
} 

file { [ $docroot, "${confdir}/conf.d" ]:
ensure => directory,
} 

file { "${docroot}/index.html":
ensure => file,
source => 'puppet:///modules/nginx/index.html',
}

file { "${confdir}/nginx.conf":
ensure => file,
content => epp('nginx/nginx.conf.epp',
{
platform_nginx_user => $user,
platform_nginx_confdir => $confdir,
platform_nginx_logdir => $logdir,
platform_nginx_run_pid_path => $run_pid_path,
}),
notify => Service['nginx'],
}

file { "${confdir}/conf.d/default.conf":
ensure => file,
content => epp('nginx/default.conf.epp',
{
platform_docroot => $docroot,
}),
notify => Service['nginx'],
} 

service { 'nginx':
ensure => running,
enable => true,
}

}
