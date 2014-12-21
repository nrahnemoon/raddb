package RdMain;

use strict;
use warnings;
use Data::Dumper;

# Same as src/include/radiusd.h
use constant	L_DBG=>   1;
use constant	L_AUTH=>  2;
use constant	L_INFO=>  3;
use constant	L_ERR=>   4;
use constant	L_PROXY=> 5;
use constant	L_ACCT=>  6;


#Initialise this with a sql_connector object
sub new {

    &radiusd::radlog(L_DBG,"Creating a new RdMain");

    my $type = shift;                       # The package/type name
    my $self = {'sql_connector' => shift};  # Reference to empty hash
    return bless $self, $type;
}

sub test_for_known_user {

    #This method can return one of three possibl vaues:
    # 1 -> The user vas identified and their 

    my($self,$user) = @_;
    my $r = $self->{'sql_connector'}->one_statement_value('user_username',$user);
    return $r;
}

1;
