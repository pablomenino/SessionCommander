#!/usr/bin/perl

################################################################################
#                                                                              #
#  MFW Session Commander                                                       #
#  Version 0.5.2                                                               #
#                                                                              #
#  If you value your sanity ... beware ... http://mfw.com.ar ... is alive ...  #
#                                                                              #
#  Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino@gmail.com>      #
#                                                                              #
#  -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
#                                                                              #
#  This program is free software; you can redistribute it and/or modify        #
#  it under the terms of the GNU General Public License as published by        #
#  the Free Software Foundation; either version 2 of the License, or           #
#  (at your option) any later version.                                         #
#                                                                              #
#  This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
#  GNU General Public License for more details.                                #
#                                                                              #
#  -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
#                                                                              #
#  Version Control:                                                            #
#                                                                              #
#    * Wed Mar 3 2010 Pablo Meniño <pablo.menino@gmail.com> 0.5.2              #
#      - RDP support.                                                          #
#      - RDP/VNC support the password feature.                                 #
#      - Now we use the extra options configure in the configuration file.     #
#                                                                              #
#    * Tue Mar 2 2010 Pablo Meniño <pablo.menino@gmail.com> 0.5.1              #
#      - Fix bugs on tsock (now is executed in the same console).              #
#                                                                              #
#    * Tue Mar 2 2010 Pablo Meniño <pablo.menino@gmail.com> 0.5                #
#      - tsock support (proxy).                                                #
#                                                                              #
#    * Mon Mar 1 2010 Pablo Meniño <pablo.menino@gmail.com> 0.4                #
#      - Session control for vnc.                                              #
#      - Better configuration file.                                            #
#                                                                              #
#    * Sun Feb 28 2010 Pablo Meniño <pablo.menino@gmail.com> 0.3               #
#      - Fix non printable character in logging file.                          #
#                                                                              #
#    * Thu Feb 25 2010 Pablo Meniño <pablo.menino@gmail.com> 0.2               #
#      - Session control for telnet.                                           #
#      - logging to file.                                                      #
#                                                                              #
#    * Mon Feb 22 2010 Pablo Meniño <pablo.menino@gmail.com> 0.1               #
#      - Initial beta version.                                                 #
#      - Session control for ssh2.                                             #
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

#----------------------------------------------------------------------
# Variables -----------------------------------------------------------

# Version Control
my $version = "0.5.2";
my $config_version = "0.5";

# Configuration file format ... that can be opened
my @version_check = ("0.1", "0.2", "0.3", "0.4", "0.5");

# Home directory
my $home = $ENV{"HOME"};

# Creates an unusual filename based on nanoseconds so that
# you don't accidentally overwrite another logfile.
my $nano = `date '+%d-%m-%Y_%H-%M-%S'`;
# Remove return line
chomp($nano);
$nano = "_" . $nano;

# Adds the file extension
my $extension_log=".log";
my $extension_log_fix=".fix.log";

# The location of executable
my $ssh = `which ssh`;
my $telnet = `which telnet`;
my $tee = `which tee`;
my $tr = `which tr`;
my $tar = `which tar`;
my $vim = `which vim`;
my $gedit = `which gedit`;
my $rm = `which rm`;
my $tsocks = `which tsocks`;
my $rdesktop = `which rdesktop`;
my $vnc = `which vncviewer`;
# my $tsocks = "/usr/bin/tsocks";
# my $vnc = "/usr/bin/vncviewer";
# Remove return line
chomp($ssh);
chomp($telnet);
chomp($tee);
chomp($tr);
chomp($tar);
chomp($vim);
chomp($gedit);
chomp($rm);
chomp($tsocks);
chomp($rdesktop);
chomp($vnc);

my $command_tsock_on = "source " . $tsocks . " on;";
my $command_tsock_off = "source " . $tsocks . " off;";

# The default directory to be store the log files
my $logdir = $home . "/Syslog/" ;

# Show the command before running it?
my $show_cmd = 0 ;

# Command to execute
my $command = "" ;

# Configuration variables
my ($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom) = "";

# Configuration dir
my $cfg_dir_filename = $home . "/.MFW-TechNet/SessionCommander/" ;

# Configuration File
my $cfg_filename = $cfg_dir_filename . "MFW-SessionCommander.config" ;

# Directory Mask
my $DirMask = 0700;

#----------------------------------------------------------------------
# Functions -----------------------------------------------------------

sub print_help()
{
	print "MFW Session Commander - Version $version\n";
	print "Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino\@gmail.com>\n";
	print "\n";
	print "Usage: $0 [options] SessionName\n";
	print "\n";
	print "options:\n";
	print "  --print_help               - Print this help\n";
	print "  --print_version            - Print version info\n";
	print "  --start_session            - Start Session Stored in Configuration File\n";
	print "  --print_sessions_names     - Print session names stored in configuration file\n";
	print "  --print_session_config     - Print session config stored in configuration file\n";
	print "  --edit_config_vi           - Edit configuration from console\n";
	print "  --edit_config_gedit        - Edit configuration from x11\n";
	print "\n";
	print "Example:\n";
	print "  ./$0 --start_session NORC-SSH\n";
	print "  This command load configuration for NORC server from configuration file, and start ssh session\n";
	print "\n";
}

sub print_version()
{
	print "MFW Session Commander - Version $version\n";
	print "Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino\@gmail.com>\n";
	print "\n";
	print "If you value your sanity ... beware ... http://mfw.com.ar ... is alive ...\n";
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

		# Create directory ...
		#if ( mkdir ($dir_to_check, $Mask_Dir) )
		#{
			#$return_value = 0;
		#} 
		#else 
		#{
			#$return_value = 1;
			#print $!;
		#}

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
#  MFW Session Commander                                                       #
#  Configuration  File                                                         #
#                                                                              #
#  If you value your sanity ... beware ... http://mfw.com.ar ... is alive ...  #
#                                                                              #
#  Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino\@gmail.com>      #
#                                                                              #
################################################################################

ConfVersion	0.5	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL

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

# Name	ComType	HostName	User	Port	Password	x11Forward	Loggin	LogPath	FixChars	FixCompactOriginal	LogMask	UseSock	OptCom
localhost	ssh2	127.0.0.1	22	NULL	NULL	NULL	NULL	NULL	NULL	NULL	0600	NULL	NULL

# End file.
";
		
	sysopen(INITCFGFILE, $file_to_init, O_RDWR|O_EXCL|O_CREAT , $Mask_Dir);
	printf INITCFGFILE $init_value;
	close (INITCFGFILE); 
	return 0;

}

sub print_sessions_names()
{

	print "MFW Session Commander - Version $version\n";
	print "Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino\@gmail.com>\n";
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

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom) = split( "\t", $_, 14);
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

	print "MFW Session Commander - Version $version\n";
	print "Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino\@gmail.com>\n";
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

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom) = split( "\t", $_, 14);
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
		my $init_value = "-= MFW-SessionCommander - Version $version =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n\n-= LogFile Start - $nano =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n\n";

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

print "MFW Session Commander - Version $version\n";
print "Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino\@gmail.com>\n";
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
			$command = $command . $ssh;
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
				$command = $command . " " . $User. "@";
			}
			$command = $command . $HostName . " -p " . $Port;
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
			system($command);
			#system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
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
			$command = $command . $telnet;
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
			system($command);
			#system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
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
				$command = $command . " echo \"" . $Password . "\" ";
			}
			$command = $command . $vnc;
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
			system($command);
			#system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
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
			system($command);
			#system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
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
		#$command = $command . " -czvf \"" . $logdir . $LogPath . $Name . $nano . $extension_log . ".tar.gz\" \"" . $logdir . $LogPath . $Name . $nano . $extension_log . "\"";
		$show_cmd && print "% $command\n" ;
		system($command) == 0 or die "ERROR: system() exec failed: $!\n" ;
		
		# Delete original file, leave only the tar.gz file
		$command = $rm;
		# Change directory ... is safe.
		if ( !chdir($logdir . $LogPath))
		{
			die "ERROR: chdir() exec failed: $!\n" 
		}
		$command = $command . " -f \"" . $Name . $nano . $extension_log . "\"";
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

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom) = split( "\t", $_, 14);
		
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

			($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom) = split( "\t", $_, 14);
		
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
	($Name, $ComType, $HostName, $Port, $User, $Password, $x11Forward, $Loggin, $LogPath, $FixChars, $FixCompactOriginal, $LogMask, $UseSock, $OptCom) = split( "\t", $tmp_line, 14);
}

return $return_value;

}

sub edit_config_vi()
{
	print "MFW Session Commander - Version $version\n";
	print "Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino\@gmail.com>\n";
	print "\n";
	print "Configuration editor:\n";

	if ( check_config_version() == 0 )
	{
		$command = $vim;
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

sub edit_config_gedit()
{
	print "MFW Session Commander - Version $version\n";
	print "Copyright © 2010 - MFW TechNet - Pablo Meniño <pablo.menino\@gmail.com>\n";
	print "\n";
	print "Configuration editor:\n";

	if ( check_config_version() == 0 )
	{
		$command = $gedit;
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
		case "--edit_config_vi"
		{
			edit_config_vi();
		}
		case "--edit_config_gedit"
		{
			edit_config_gedit();
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
		else
		{
			print_help();
		}
	}
}

#----------------------------------------------------------------------
# Main - End ----------------------------------------------------------
#----------------------------------------------------------------------
