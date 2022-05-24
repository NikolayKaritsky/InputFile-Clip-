#!/usr/bin/perl
use strict;
use warnings;

use CGI qw/:standard/;
use Fcntl;

my $wwwFolder='../www/';
my $filePath='clip/files/';

sub urldecode              # Декодирование запроса
{             
	my $val= shift ;
	$val=~s/\+/ /g;
	$val=~s/%([0-9A-H]{2})/pack('C',hex($1))/ge;
	return $val;
}

sub getFilesList
{
	opendir CLIP, $wwwFolder.$filePath;
	my @files = grep(!/^\.\.?$/, readdir CLIP);
	if (@files)
	{    
	   	my $elem = <<__ELEM__;
<span class="nwrap" id="loaded_file_%file_id%"><a href="%file_path%%file_name%" download title="Скачать файл">%file_name%</a>
<span><a href="javascript:void(0)" class="red" onClick="remove_loaded_file('%file_name%',%file_id%)">[x]</a></span></span>
__ELEM__

	    my $i=0;
#	my @output = map {my $tmp=$elem; chomp($tmp); $tmp=~s/%file_path%/$filePath/g; $tmp=~s/%file_name%/$_/g; $tmp} @files;
		my @output = map {
			my $tmp=$elem; chomp($tmp); $tmp=~s/%file_path%/$filePath/g; $i++; $tmp=~s/%file_id%/$i/g; $tmp=~s/%file_name%/$_/g; $tmp
			} @files;
		closedir CLIP;
		$,="; ";
		print @output;
	}
	else
	{
		print '<span class="gray">Нет загруженных файлов</span>';
	}
}




my $request=$ENV{'REQUEST_METHOD'};
print "Content-Type: text/html;\n\n";

if ($request eq 'GET')
{
	my %query = map {my ($param, $value) = split("=", $_); $param, urldecode($value)} split('&',$ENV{'QUERY_STRING'});

	if ($query{action} eq 'get_loaded_files')
	{
    getFilesList;
	}
	elsif ($query{action} eq 'remove_file')
	{
	my $fileName=$wwwFolder.$filePath.$query{'file_name'};

	unlink $fileName if (-e $fileName);

    getFilesList;
	}
}
else
{
	my %query = map {$_, param($_) } param;

	if ($query{action} eq 'upload_files')
	{
		delete $query{action};
	    my $i=0;
		foreach (keys %query)
		{
			my $file_to_write=$query{$_};
			my $fileName = $wwwFolder.$filePath.$_;
    	    sysopen F, $fileName, O_CREAT | O_WRONLY, 0444;
        	binmode F or die "Cannot binmode $fileName $!\n";
	        print F while (<$file_to_write>);
    	    close F;
		}
	getFilesList;
	}

}


