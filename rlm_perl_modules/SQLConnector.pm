package SQLConnector;

use strict;
use Data::Dumper;
use DBI;

# Same as src/include/radiusd.h
use constant	L_DBG=>   1;
use constant	L_AUTH=>  2;
use constant	L_INFO=>  3;
use constant	L_ERR=>   4;
use constant	L_PROXY=> 5;
use constant	L_ACCT=>  6;



sub new {

    &radiusd::radlog(L_DBG,"Creating a new SQLConnector");

    my $type = shift;            # The package/type name
    my $self;
    my $db_server   = 'localhost';
    my $db_name     = 'rd';
    my $db_user     = 'rd';
    my $db_password = 'rd';

    $self->{'db_handle'}    =   DBI->connect("DBI:mysql:database=$db_name;host=$db_server",
                                    "$db_user", 
                                    "$db_password",
                                     { RaiseError => 1,
                                       AutoCommit => 1 }) || die "Unable to connect to $db_server because $DBI::errstr";
    $self->{'db_handle'}->{'mysql_auto_reconnect'} = 1;
    return bless $self, $type;
}


sub DESTROY
{
   print "   SQLConnector::DESTROY called\n";
}


sub query {
    my($self,$q)        = @_;
    my $StatementHandle = $self->{'db_handle'}->prepare("$q");
    $StatementHandle->execute();
    return $StatementHandle->fetchall_arrayref();
}


sub prepare_statements {

    my($self)        = @_;
    #____________ Description ____________________________________________________
    #__ This file prepares the various SQL queries which will later be executed___
    #_____________________________________________________________________________

    #List the statements here so we can loop through them and 'finish' them
    $self->{'statements'}   =   [ 
                                    'user_username',
                                    'realms_for_nas',
                                    'rd_tags_for_user'
                                ];

    #==================================================
    #=== Return only ONE line / Require One value =====
    #==================================================

    #____ Users Related Queries ________
    $self->{'user_username'}    = $self->{'db_handle'}->prepare("SELECT u.username,r.name realm_name,u.active FROM users u LEFT JOIN groups g ON u.group_id=g.id LEFT JOIN realms r ON u.realm_id=r.id where u.username=? AND g.name='Users';");


    #___ Tag Related Queries _______
    $self->{'rd_tags_for_user'} = $self->{'db_handle'}->prepare(
        "SELECT radcheck.attribute userAttribute, radcheck.value userTagValue,  ".
        "radgroupcheck.attribute groupAttribute, radgroupcheck.value groupTagValue ".
        "FROM radusergroup RIGHT JOIN radcheck ON radcheck.value=radusergroup.username ". 
        "LEFT JOIN radgroupcheck ON radgroupcheck.groupname=radusergroup.groupname ".
        "WHERE (radcheck.username=? and radcheck.attribute='User-Profile' and radgroupcheck.attribute LIKE 'Rd-Tag-%') ".
        "OR (radcheck.attribute LIKE 'Rd-Tag-%' AND radcheck.username=?) ORDER BY radusergroup.priority DESC;"
    );
    $self->{'tags_for_nas'}   = $self->{'db_handle'}->prepare(
        "SELECT tags.name FROM na_tags LEFT JOIN nas ON nas.id=na_tags.na_id ".
        "LEFT JOIN tags ON tags.id=na_tags.tag_id  WHERE nasname=?;"
    );


    #___ Realm Related Queries _____
    $self->{'realms_for_nas'}   = $self->{'db_handle'}->prepare(
        "SELECT realms.name FROM na_realms LEFT JOIN nas ON nas.id=na_realms.na_id ".
        "LEFT JOIN realms ON realms.id=na_realms.realm_id  WHERE nasname=?;"
    );

}



#Only return one line for the query of a nasname
sub one_statement_value {   #Select the statement handle name and supply the value

    my($self,$statement_name,$value)  = @_;

    $self->{"$statement_name"}->execute($value)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;

    my $hash_ref        = $self->{$statement_name}->fetchrow_hashref();
    return $hash_ref;   # Return a hash with ALL the fields in the NAS 
}


sub one_statement_value_return_all {   #Select the statement handle name and supply the value

    my($self,$statement_name,$value)  = @_;
    $self->{"$statement_name"}->execute($value)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;

    my $hash_ref        = $self->{$statement_name}->fetchall_arrayref();;
    return $hash_ref;   # Return an array with ALL the fields
}

sub one_statement_value_value_return_all {   #Select the statement handle name and supply the value

    my($self,$statement_name,$value1,$value2)  = @_;
    $self->{"$statement_name"}->execute($value1,$value2)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;

    my $array_ref        = $self->{$statement_name}->fetchall_arrayref();
    return $array_ref;   # Return an array with ALL the fields 
}

sub one_statement_no_return {
    my($self,$statement_name,$value)  = @_;

    my $fb = $self->{"$statement_name"}->execute($value)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;

    #Auto Commmit had to be turned on because of mysql_auto_reconnect
    #$self->{"db_handle"}->commit();

    return;
}


sub one_statement_no_return_value_value {
    my($self,$statement_name,$value1,$value2)  = @_;

    my $fb = $self->{"$statement_name"}->execute($value1,$value2)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;

    #Auto Commmit had to be turned on because of mysql_auto_reconnect
    #$self->{"db_handle"}->commit();
    return;
}

sub no_return_three_values {

    my($self,$statement_name,$value1,$value2,$value3) = @_;
    my $fb = $self->{"$statement_name"}->execute($value1,$value2,$value3)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;
    #Auto Commmit had to be turned on because of mysql_auto_reconnect
    #$self->{"db_handle"}->commit();
    return;
}

sub no_return_five_values {

    my($self,$statement_name,$value1,$value2,$value3,$value4,$value5) = @_;
    my $fb = $self->{"$statement_name"}->execute($value1,$value2,$value3,$value4,$value5)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;
    #Auto Commmit had to be turned on because of mysql_auto_reconnect
    #$self->{"db_handle"}->commit();
    return;
}


#Only return one line for the query 
sub one_statement_value_value_value {   #Select the statement handle name and supply the value

    my($self,$statement_name,$value1,$value2,$value3)  = @_;

    $self->{"$statement_name"}->execute($value1,$value2,$value3)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;

    my $hash_ref        = $self->{$statement_name}->fetchrow_hashref();
    return $hash_ref;   # Return a hash with ALL the fields in the NAS 
}


sub many_statement_value {

    my($self,$statement_name,$value)  = @_;

    $self->{"$statement_name"}->execute($value)
        or die "Couldn't execute statement: " .$self->{$statement_name}->errstr;

    my $array_ref        = $self->{$statement_name}->fetchall_arrayref();
    return $array_ref;   # Return a hash with ALL the fields in the NAS 
}



sub finish_statements {   #Select the statement handle name and supply the value

    my($self)  = @_;

    foreach my $item(@{$self->{statements}}){

       # print "Destroying statement handle: $item\n";
        $self->{$item}->finish();

    }
}



1;
