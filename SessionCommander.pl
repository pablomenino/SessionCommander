#!/usr/bin/perl

################################################################################
#                                                                              #
#  Session Commander                                                           #
#  Version 0.6.3                                                               #
#                                                                              #
#  Copyright © 2023 - Pablo Meniño <pablo.menino@mfwlab.com>                   #
#                                                                              #
################################################################################

#----------------------------------------------------------------------
# Use declaration -----------------------------------------------------

require 5.003;
use strict;
use warnings;
use Time::Local;
use Cwd;
use File::Basename;
use Switch;
use File::Path;
use Fcntl;
use Term::Menus;

#----------------------------------------------------------------------
# Variables -----------------------------------------------------------

# Version Control
my $version = "0.6.3";
my $config_version = "0.6";

# Configuration file format ... that can be opened
my @version_check = ("0.6");

# Home directory
my $home = $ENV{"HOME"};

# Log file name ... don't accidentally overwrite another logfile.
my $nano = `date '+%Y-%m-%d_%H-%M-%S'`;
# Remove return line
chomp($nano);
$nano = "_" . $nano;

# Adds the file extension
my $extension_log=".log";
# Remove escape characters from log file
my $extension_log_fix=".fix.log";

# The location of executable
my $ssh = `which ssh 2>&1`;
my $telnet = `which telnet 2>&1`;
my $tee = `which tee 2>&1`;
my $tr = `which tr 2>&1`;
my $tar = `which tar 2>&1`;
my $nano_edit = `which nano 2>&1`;
my $rm = `which rm 2>&1`;
my $tsocks = `which tsocks 2>&1`;
my $rdesktop = `which rdesktop 2>&1`;
my $vnc = `which vncviewer 2>&1`;
# Remove return line
chomp($ssh);
chomp($telnet);
chomp($tee);
chomp($tr);
chomp($tar);
chomp($nano_edit);
chomp($rm);
chomp($tsocks);
chomp($rdesktop);
chomp($vnc);

# Prepare sock command in case you need it
my $command_tsock_on = "source " . $tsocks . " on;";
my $command_tsock_off = "source " . $tsocks . " off;";

# Default directory to store the log files
my $logdir = $home . "/SessionCommander/Logs/" ;

# Show the command before running it? (Debug)
my $show_cmd = 0 ;

# Command to execute // Prepare
my $command = " " ;

# Configuration variables
my ($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom, $SSHRemCom) = "";

# Configuration dir
my $cfg_dir_filename = $home . "/.SessionCommander/" ;

# Configuration File
my $cfg_filename = $cfg_dir_filename . "SessionCommander.config" ;

# Directory Mask // Protect configuration file
my $DirMask = 0700;

# Logging expect vars
my $command_nolog = "";
my $logfile_expect = "";

#----------------------------------------------------------------------
# Functions -----------------------------------------------------------

sub print_help()
{
	print "Session Commander - Version $version\n";
	print "Copyright © 2023 - Pablo Meniño <pablo.menino\@mfwlab.com.com>\n";
	print "\n";
	print "Usage: $0 [options] SessionName\n";
	print "\n";
	print "options:\n";
	print "  --print_help               - Print this help\n";
	print "  --print_version            - Print version info\n";
	print "  --start_session            - Start Session Stored in Configuration File\n";
	print "  --print_sessions_names     - Print session names stored in configuration file\n";
	print "  --print_session_config     - Print session config stored in configuration file\n";
	print "  --edit_config_nano         - Edit configuration from console\n";
	print "  --menu                     - Display a menu to select connection from a list\n";
	print "  --menu item_to_filter      - Display a menu and filter menu items from the list (like search)\n";
	print "\n";
	print "Example:\n";
	print "  $0 --start_session NORC-SSH\n";
	print "  This command load configuration for NORC server from configuration file, and start ssh session\n";
	print "\n";
}

sub print_version()
{
	print "Session Commander - Version $version\n";
	print "Copyright © 2023 - Pablo Meniño <pablo.menino\@mfwlab.com>\n";
	print "\n";
}

sub check_dir_file()
{
	my ($file_to_check) = @_;
	my $return_value = 1;

	# Check directory or file exists.
	if (-e $file_to_check)
	{
		$return_value = 0;
	} 
	else 
	{
		$return_value = 1;
	}

	return $return_value;
}

sub make_log_dir()
{
	
	my ($dir_to_check, $Mask_Dir) = @_;
	my $return_value = 1;
	
	if ( &check_dir_file($dir_to_check) != 0 )
	{

		# Create directory ...
		mkpath($dir_to_check, {verbose => 0, mode => $Mask_Dir, error => \my $err} );
		if (@$err)
		{
			$return_value = 1;
			for my $diag (@$err)
			{
				my ($file, $message) = %$diag;
				if ($file eq '')
				{
					print "ERROR: Cant't make directory $dir_to_check. General error: $message\n";
				}
				else
				{
					print "ERROR: Cant't make directory $dir_to_check. Problem unlinking $file: $message\n";
				}
			}
		
		}
		else
		{
			$return_value = 0;
		}

	}
	else 
	{
		$return_value = 0;
	}

	return $return_value;

}

sub make_log_init()
{
	
	my ($file_to_init, $Mask_Dir) = @_;
	my $return_value = 1;
	my $init_value = "################################################################################
#                                                                              #
#  Session Commander                                                           #
#  Configuration  File                                                         #
#                                                                              #
#  Copyright © 2023 - Pablo Meniño <pablo.menino\@mfwlab.com>                  #
#                                                                              #
################################################################################

ConfVersion	0.6	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL

# IMPORTANT:
#  Use TAB's to separate config.
#  No store 2 connections with the same name (this app is case sensitive, so use different characters combination).
#    NORC is not the same to Norc (Upper/Lower characters have different values in ASCII table).

# CFG Values:
#   Name: Name of the saved profile.
#   ComType: Connection Type, for now we can use ssh2, telnet and VNC.
#   HostName: Hostname or ip adderss.
#   Port: Port address.
#   User: User name.
#   Password: Password for the account. (not working yet).
#   x11Forward: Forward x11 port. (Only for ssh2 and telnet).
#   Loggin: Loggin session to text file. (Only for ssh2 and telnet).
#   LogPath: Directory to store the logfile. (Only for ssh2 and telnet).
#   FixChars: Remove non printable character, this makes new file an preserve the original. (Only for ssh2 and telnet).
#   FixCompactOriginal: If FixChars is true, then compact in tar.gz format the original file. (Only for ssh2 and telnet).
#   LogMask: Mask for logging file.
#   UseSock: Use tsocks.
#   OptCom: Use extra options on command line.
#   SSHRemCom: Remote command on SHH sesion.

# Name	ComType	HostName	Port	User	Password	x11Forward	Loggin	LogPath	FixChars	LogMask	UseSock	OptCom	SSHRemCom
localhost	ssh2	127.0.0.1	22	NULL	NULL	NULL	NULL	NULL	NULL	NULL	0600	NULL	NULL	NULL

# End file.
";
		
	sysopen(INITCFGFILE, $file_to_init, O_RDWR|O_EXCL|O_CREAT , $Mask_Dir);
	printf INITCFGFILE $init_value;
	close (INITCFGFILE); 
	return 0;

}

sub print_sessions_names()
{

	print "Session Commander - Version $version\n";
	print "Copyright © 2023 - Pablo Meniño <pablo.menino\@mfwlab.com>\n";
	print "\n";
	print "Session Stored in configuration file:\n";

	my $nth = "";

	# CFG
	open (FILECFG, $cfg_filename);
	while ( (<FILECFG>) )
	{
		chomp($_);
		$nth = substr($_, 0, 1);
	
		# If not caracter NULL or #, then read config.
		if ( $nth ne "#" and $nth ne "" )
		{

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom, $SSHRemCom) = split( "\t", $_, 15);
			if ($Name ne "ConfVersion")
			{
				print " -->> Name: $Name - ComType: $ComType - HostName: $HostName - Port: $Port\n";
			}

		}
	}
	close (FILECFG);

	print "End of configuration file\n";

}

sub print_session_config()
{

	print "Session Commander - Version $version\n";
	print "Copyright © 2023 - Pablo Meniño <pablo.menino\@mfwlab.com>\n";
	print "\n";
	print "Session Stored in configuration file:\n";

	my $nth = "";
	my ($config_name) = @_;

	# CFG
	open (FILECFG, $cfg_filename);
	while ( (<FILECFG>) )
	{
		chomp($_);
		$nth = substr($_, 0, 1);
	
		# If not caracter NULL or #, then read config.
		if ( $nth ne "#" and $nth ne "" )
		{

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom, $SSHRemCom) = split( "\t", $_, 15);
			if ($Name eq $config_name)
			{
				print " -->> Name: $Name - ComType: $ComType - HostName: $HostName - Port: $Port\n";
			}

		}
	}
	close (FILECFG);

	print "End of configuration file\n";

}

sub create_logfile()
{

	my ($dir_to_init, $file_to_init) = @_;
	
	if ( &make_log_dir($dir_to_init, $DirMask) == 0 )
	{
		
		my $return_value = 1;
		my $init_value = "-= SessionCommander - Version $version =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n\n-= LogFile Start - $nano =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n\n";

		sysopen(INITCFGFILE, $file_to_init, O_RDWR|O_EXCL|O_CREAT , oct($LogMask));
		printf INITCFGFILE $init_value;
		close (INITCFGFILE); 
		return 0;

	}
	else
	{
		print "ERROR: Can't make directory for store logfiles, check the configuration file\n";
		exit 0;
	}

}

sub start_session()
{

print "Session Commander - Version $version\n";
print "Copyright © 2023 - Pablo Meniño <pablo.menino\@mfwlab.com>\n";
print "\n";
print "Starting ...\n";
print " -->> Name: $Name - ComType: $ComType - HostName: $HostName - Port: $Port\n\n";

switch ($ComType)
	{
		case "ssh2"
		{
			if ($UseSock eq "true")
			{
				$command = $tsocks . " ";
			}
			$command = $command . " " . $ssh;
			if ($OptCom ne "NULL")
			{
				$command = $command . " " . $OptCom;
			}
			if ($x11Forward eq "true")
			{
				$command = $command . " -X";
			}
			if ($User ne "NULL")
			{
				$command = $command . " " . $User. "@" . $HostName;
			}
            else
            {
                $command = $command . " " . $HostName;
            }
			if ($Port ne "NULL")
			{
				$command = $command . " -p " . $Port;
			}
			if ($SSHRemCom ne "NULL")
			{
				$command = $command . " " . "\"" . $SSHRemCom . "\"";
			}
			if ($Loggin eq "true")
			{
				$command_nolog = $command;
                $logfile_expect = "\"" . $logdir . $LogPath . $Name . $nano . $extension_log . "\"";
                $command = $command . " | $tee -a \"" . $logdir . $LogPath . $Name . $nano . $extension_log . "\"";
			}
			# Open tsocks
			if ($UseSock eq "true")
			{
				system($command_tsock_on);
			}
			$show_cmd && print "% $command\n" ;
			# Execute command
			if ( ($Password ne "NULL") and ($Loggin eq "true"))
			{
                system( qq{expect -c 'spawn  $command_nolog; log_file $logfile_expect; expect '*yes/no*' {send "yes\r"; exp_continue;} '*?assword:*' {send "$Password\r"}; interact;'} ) == 0 or die "ERROR: system() exec failed: $!\n" ;
			}
			elsif ($Password ne "NULL")
			{
                system( qq{expect -c 'spawn  $command; expect '*yes/no*' {send "yes\r"; exp_continue;} '*?assword:*' {send "$Password\r"}; interact;'} ) == 0 or die "ERROR: system() exec failed: $!\n" ;
			}
            else
            {
                system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
            }
			# close tsocks
			if ($UseSock eq "true")
			{
				system($command_tsock_off);
			}

		}
		case "telnet"
		{
			if ($UseSock eq "true")
			{
				$command = $tsocks . " ";
			}
			$command = $command . " " . $telnet;
			if ($OptCom ne "NULL")
			{
				$command = $command . " " . $OptCom;
			}
			if ($User ne "NULL")
			{
				$command = $command . " -l " . $User;
			}
			$command = $command . " " . $HostName . " " . $Port;
			if ($Loggin eq "true")
			{
				$command = $command . " | $tee -a \"" . $logdir . $LogPath . $Name . $nano . $extension_log . "\"";
			}
			# Open tsocks
			if ($UseSock eq "true")
			{
				system($command_tsock_on);
			}
			$show_cmd && print "% $command\n" ;
			# Execute command
			system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
			# close tsocks
			if ($UseSock eq "true")
			{
				system($command_tsock_off);
			}
			
		}
		case "vnc"
		{
			if ($UseSock eq "true")
			{
				$command = $tsocks . " ";
			}
			if ($Password ne "NULL")
			{
				$command = $command . " echo \"" . $Password . "\" | ";
			}
			$command = $command . $vnc;
			if ($Password ne "NULL")
			{
				$command = $command . " -passwdInput true";
			}
			if ($OptCom ne "NULL")
			{
				$command = $command . " " . $OptCom;
			}
			$command = $command . " " . $HostName . "::" . $Port;
			# Open tsocks
			if ($UseSock eq "true")
			{
				system($command_tsock_on);
			}
			$show_cmd && print "% $command\n" ;
			# Execute command
			system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
			# close tsocks
			if ($UseSock eq "true")
			{
				system($command_tsock_off);
			}
			
		}
		case "RDP"
		{
			if ($UseSock eq "true")
			{
				$command = $tsocks . " ";
			}
			$command = $command . $rdesktop;
			if ($User ne "NULL")
			{
				$command = $command . " -u " . $User;
			}
			if ($Password ne "NULL")
			{
				$command = $command . " -p " . $Password;
			}
			if ($OptCom ne "NULL")
			{
				$command = $command . " " . $OptCom;
			}
			$command = $command . " " . $HostName . ":" . $Port;
			# Open tsocks
			if ($UseSock eq "true")
			{
				system($command_tsock_on);
			}
			$show_cmd && print "% $command\n" ;
			# Execute command
			system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
			# close tsocks
			if ($UseSock eq "true")
			{
				system($command_tsock_off);
			}
			
		}
		else
		{
			print_help();
		}
	}

}

sub fix_chars()
{
	
	if ($Loggin eq "true" and $FixChars eq "true")
	{
		$command = $tr;
		$command = $command . " -dc '[:alnum:][:space:][:punct:]' < \"" . $logdir . $LogPath . $Name . $nano . $extension_log . "\" > \"" . $logdir . $LogPath . $Name . $nano . $extension_log_fix . "\"";
		$show_cmd && print "% $command\n" ;
		system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
	}

	if ($Loggin eq "true" and $FixChars eq "true" and $FixCompactOriginal eq "true")
	{
		$command = $tar;
		# Change directory to not store path.
		if ( !chdir($logdir . $LogPath))
		{
			die "ERROR: chdir() exec failed: $!\n" 
		}
		$command = $command . " -czf \"" . $Name . $nano . $extension_log . ".tar.gz\" \"" . $Name . $nano . $extension_log . "\"";
		$show_cmd && print "% $command\n" ;
		system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
		
		# Delete original file, leave only the tar.gz file
		$command = $rm;
		# Change directory ... is safe.
		if ( !chdir($logdir . $LogPath))
		{
			die "ERROR: chdir() exec failed: $!\n" 
		}
        $command = $command . " \"" . $Name . $nano . $extension_log . "\"";
		$show_cmd && print "% $command\n" ;
		system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
		
	}

}

sub check_config_version()
{

	my $nth = "";
	my $findsession = "false";
	my $return_value = 1;

	# CFG
	open (FILECFG, $cfg_filename);
	while (<FILECFG>)
	{
		chomp($_);
		$nth = substr($_, 0, 1);
	
		# If not caracter NULL or #, then read config.
		if ( $nth ne "#" and $nth ne "" )
		{

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom, $SSHRemCom) = split( "\t", $_, 15);
		
			if ( $Name eq "ConfVersion" )
			{
				$findsession = "true";
				$return_value = 0;
			}

		}
	}
	close (FILECFG);

	# If value version_check is found in cfg file ... then check if this is supported.
	if ($Name eq "true" )
	{
		my $cfg_file_support = 1;
		my $version_check = "";
		foreach $version_check (@version_check)
		{
			if ( $version_check eq $HostName )
			{
				$cfg_file_support = 0;
			}
			else
			{
				$cfg_file_support = 1;
			}
		}
		
		# If old version, then migrato to new.
		if ( ($cfg_file_support == 0) && ($HostName ne $config_version) )
		{
			# Not implemented ... is not necessary on this version
			# &migrate_config($from_version, $to_version);
		}
		elsif ( $cfg_file_support == 0 )
		{
			# Not supported version
			$return_value = 1;
		}
		
	}

	return $return_value;

}

sub read_config()
{

	my $nth = "";
	my $findsession = "false";
	my $return_value = 1;
	my $tmp_line = "";
	
	# CFG
	open (FILECFG, $cfg_filename);
	while (<FILECFG>)
	{
		
		chomp($_);
		$nth = substr($_, 0, 1);
		
		# If not caracter NULL or #, then read config.
		if ( $nth ne "#" and $nth ne "" )
		{

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom, $SSHRemCom) = split( "\t", $_, 15);
		
			if ( $Name eq $ARGV[1] )
			{
				$tmp_line = $_;
				$findsession = "true";
				$return_value = 0;
			}

		}
	}
	close (FILECFG);

if ($findsession eq "true")
{
	($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom, $SSHRemCom) = split( "\t", $tmp_line, 15);
}

return $return_value;

}

sub edit_config_nano()
{
	print "Session Commander - Version $version\n";
	print "Copyright © 2016 - Pablo Meniño <pablo.menino\@gmail.com>\n";
	print "\n";
	print "Configuration editor:\n";

	if ( check_config_version() == 0 )
	{
		$command = $nano_edit;
		$command = $command . " " . $cfg_filename;
		$show_cmd && print "% $command\n" ;
		system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
	}
	else
	{
		print "ERROR: The configuration file is not a supported version.";
		exit 0;
	}
}

sub display_menu()
{

	my $nth = "";
    my @conn_list;
    my ($filter_exp) = @_;

	# CFG
	open (FILECFG, $cfg_filename);
	while ( (<FILECFG>) )
	{
		chomp($_);
		$nth = substr($_, 0, 1);
	
		# If not caracter NULL or #, then read config.
		if ( $nth ne "#" and $nth ne "" )
		{

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom, $SSHRemCom) = split( "\t", $_, 15);
			if ($Name ne "ConfVersion")
			{
                push @conn_list, $Name;
			}

		}
	}
	close (FILECFG);

    my %Menu_1=(
    
    Name   => 'Menu_1',
    Display => 15,
    Item_1 => {
        Text   => "]Convey[",
        Convey => \@conn_list,
        Include => qr/$filter_exp/i,
    },
    Select => 'One',
	Banner => "Session Commander - Version $version\n".
	"Copyright © 2023 - Pablo Meniño <pablo.menino\@mfwlab.com>\n".
	"\n".
	"Session Stored in configuration file:\n"
    );
    
    my @selections=&Menu(\%Menu_1);
    return  @selections[0];
}

#----------------------------------------------------------------------
# Main - Begin --------------------------------------------------------

# Check if configuration file exists.
if ( &check_dir_file($cfg_filename) != 0 )
{
	if ( &make_log_dir($cfg_dir_filename, $DirMask) == 0 )
	{
	
		if ( &make_log_init($cfg_filename, $DirMask) != 0 )
		{
			print "ERROR: Can't make initial configuration file\n";
			exit 0;
		}
		
	}
	else
	{
		print "ERROR: Can't make directory to store cfg file: $cfg_dir_filename\n";
		exit 0;
	}
}

# Check script arguments.
if (($#ARGV < 0) || ($#ARGV > 1))
{
	print_help();
}
else
{
	switch ($ARGV[0])
	{
		case "--print_help"
		{
			print_help();
		}
		case "--print_version"
		{
			print_version();
		}
		case "--edit_config_nano"
		{
			edit_config_nano();
		}
		case "--start_session"
		{
			
			if ($#ARGV != 1)
			{
				print_help();
			}
			else
			{
				if ( check_config_version() == 0 )
				{
					if ( read_config() == 0 )
					{
				
						if ( $Loggin eq "true" )
						{
							&create_logfile($logdir . $LogPath, $logdir . $LogPath . $Name . $nano . $extension_log);
						}
						start_session();
						if ( $FixChars eq "true" )
						{
							fix_chars();
						}
				
					}
					else
					{
						print "ERROR: The session name not found in configuration file. Try --print_sessions_names option to see all session names stored in configuration file.";
						exit 0;
					}
				}
				else
				{
					print "ERROR: The configuration file is not a supported version.";
					exit 0;
				}
			}
		}
		case "--print_sessions_names"
		{
			
			if ( check_config_version() == 0 )
			{
				print_sessions_names();
			}
			else
			{
				print "ERROR: The configuration file is not a supported version.";
				exit 0;
			}
			
		}
		case "--print_session_config"
		{
			if ($#ARGV != 1)
			{
				print_help();
			}
			else
			{
			
				if ( check_config_version() == 0 )
				{
					&print_session_config($ARGV[1]);
				}
				else
				{
					print "ERROR: The configuration file is not a supported version.";
					exit 0;
				}
			}
		}
		case "--menu"
		{
			# Display menu
            my $filter_exp = $ARGV[1];
            my $session_name = &display_menu($filter_exp);
            if ($session_name eq "]quit[")
			{
				print_help();
			}
            else
            {
                # Load from config
                $ARGV[1] = $session_name;
                if ( read_config() == 0 )
                {
            
                    if ( $Loggin eq "true" )
                    {
                        &create_logfile($logdir . $LogPath, $logdir . $LogPath . $Name . $nano . $extension_log);
                    }
                    start_session();
                    if ( $FixChars eq "true" )
                    {
                        fix_chars();
                    }
            
                }
                else
                {
                    print "ERROR: The session name not found in configuration file. Try --print_sessions_names option to see all session names stored in configuration file.";
                    exit 0;
                }
            }
		}
		else
		{
			print_help();
		}
	}
}

#----------------------------------------------------------------------
# Main - End ----------------------------------------------------------
#----------------------------------------------------------------------
