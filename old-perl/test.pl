#!/usr/bin/perl

use lib 'evernote-sdk-perl/lib';
use Thrift;
use Thrift::HttpClient;
use Thrift::BinaryProtocol;
use EDAMUserStore::UserStore;
use Data::Dumper;

my $user_client = new Thrift::HttpClient('https://sandbox.evernote.com/edam/user');
my $user_proto = new Thrift::BinaryProtocol($user_client);
my $user_store = new UserStoreClient($user_proto);

eval {
my $res = $user_store->checkVersion("Perl API test");
print "$resn";
};
if ($@) {
print Dumper($@);
exit;
}
