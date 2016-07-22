
#!/usr/bin/perl -w

## Written by Ryan McKay (4ryanmckay2@gmail.com)
#  September 2015
#  for UNSW Comp2041 (Software Construction) Assignment1 Shypy
#  Spec: http://www.cse.unsw.edu.au/~cs2041/15s2/assignments/shpy/

use diagnostics;
#require 'unit_tests.pl' if ($DEBUG);

$DEBUG = 0;
$DEBUG_FINE = 0;
if (@ARGV > 0 && $ARGV[0] eq "-d") {
   $DEBUG = 1;
   shift;
} elsif (@ARGV > 0 && $ARGV[0] eq "-df") {
   $DEBUG = 1;
   $DEBUG_FINE = 1;
   shift;
}



###
# Debug Funtions
###

sub debug
{
    my ($debug_m, @array) = @_;
    $size_array = @array;
    if ($size_array > 0) {
        if ($DEBUG) {
            print "$debug_m\n";
            foreach $line (@array) {
                print "$line\n";
            }
            print "\n";
        }
    } else {
        print "$debug_m\n" if ($DEBUG);
    }
}

sub debug_fine
{
    my ($debug_m, @array) = @_;
    $size_array = @array;
    if ($size_array > 0) {
        if ($DEBUG_FINE) {
            print "$debug_m\n";
            foreach $line (@array) {
                print "$line\n";
            }
            print "\n";
        }
    } else {
        print "$debug_m\n" if ($DEBUG_FINE);
    }
}


############
# Regex Functions
############

sub is_bash
{
    my ($line, $line_num) = @_ or die;
    return ($line =~ /^#!\/bin\/(?:bash|sh)/ && $line_num == '1');
}

sub is_cd
{
    my $line = shift;
    return ($line =~ /^cd/);
}

sub is_echo
{
    my $line = shift;
    return ($line =~ /^echo/);
}

sub is_test
{
    my $line = shift;
    return ($line =~ /^test/);
}

sub is_exit
{
    my $line = shift;
    return ($line =~ /^exit/);
}

sub is_read
{
    my $line = shift;
    return ($line =~ /^read/);
}

sub is_subprocess
{
    my $line = shift;
    return ($line =~ /^(?:ls|pwd|id|date)/);
}

sub is_not_empty
{
    my $line = shift;
    return ($line =~ /.+/);
}

sub is_variable_assign
{
    my $var = shift;
    return ($var =~ /\w+=\$?\w+/);

}
sub is_variable
{
    my $var = shift;
    if (is_arg($var)) {
        return 0;
    } else {
        return ($var =~ /\$\w+/);
    }
}

sub is_word
{
    my $word = shift;
    return ($word =~ /[A-Za-z]+/);
}

sub is_number
{
    my $num = shift;
    return ($num =~ /\d+/);
}

sub is_for_loop
{
    my $line = shift;
    return ($line =~ /^\s*for \w+ in/);
}

sub is_sys
{
   my $line = shift;
   return ($line =~ /^exit |^read /);
}

sub is_done
{
    my $line = shift;
    return ($line =~ /^done$/);
}

sub is_do
{
    my $line = shift;
    return ($line =~ /^do$/);
}

sub is_os
{
    my $line = shift;
    return ($line =~ /^cd /);
}

sub is_glob
{
    my $line = shift;
    return ($line =~ /^\*/);

}

sub is_arg
{
    my $line = shift;
    return ($line =~ /\$\d/);
}

sub is_if
{
    my $line = shift;
    return ($line =~ /^\s*if/);

}

sub is_elif
{
    my $line = shift;
    return ($line =~ /^\s*elif /);

}

sub is_then
{
    my $line = shift;
    return ($line =~ /^then$/);

}

sub is_else
{
    my $line = shift;
    return ($line =~ /^else:?$/);
}

sub is_fi
{
    my $line = shift;
    return ($line =~ /^fi$/);

}

sub is_sgl_quote
{
    my $line = shift;
    return ($line =~ /\'.*\'/);
}

sub is_dbl_quote
{
    my $line = shift;
    return ($line =~ /\".*\"/);
}

sub is_sgl_key
{
    my $line = shift;
    return ($line =~ /SGL_QUOTE/);
}

sub is_dbl_key
{
    my $line = shift;
    return ($line =~ /DBL_QUOTE/);
}

sub is_dbl_quote_var
{
    my $line = shift;
    return ($line =~ /\".*\$\d+.*\"/);
}

sub is_quotes
{
    my $line = shift;
    return ($line =~ /^'|^"/);
}

sub is_comment
{
    my $line = shift;
    return ($line =~ /^#/);
}

############
# Processing Functions
############

###
# Subset 0
###

sub subprocess_call
{
    my $line = shift;
    debug_fine("\nsubprocess_call():", $line);
    # load into import hash
    $IMPORT{"subprocess"} = 1 if (!exists($IMPORT{"subprocess"}));
    my @buffer = "subprocess.call([";
    my @split_line = split / /,$line;
    # multiple arguments/ tags case
    if (@split_line > 1) {
        foreach my $sub_line (@split_line) {
            $sub_line = rws_line($sub_line);
            push @buffer, "'$sub_line'";
            push @buffer, ", ";
        }
        $buffer[-1] = "])";
        push @TO_PRINT, join('', @buffer);
    # single argument/ tags case
    } else {
        push @buffer, "'$split_line[0]'])";
        push @TO_PRINT, join('', @buffer);
    }
    debug("\nAfter subprocess_call():", @TO_PRINT);
}


sub echo_call
{
    my $line = shift;
    debug_fine("In echo line:......", $line);
    my @buffer = ();
    my @sgl_buffer = ();
    my @dbl_buffer = ();
    # split to seperate and remove echo and add python syntax print
    my @split_line = split / /,$line, 2;
    push @buffer, "print ";
    shift @split_line;
    $line = shift @split_line;
    debug_fine("echo_call(): after shift:..... ", $line);
    if (is_sgl_quote($line) || is_dbl_quote($line)) {
        $line = extract_quotes($line, \@sgl_buffer, \@dbl_buffer);
        debug_fine("echo_call(): sgl_quote capture: ", @sgl_buffer);
        debug_fine("echo_call(): dbl_quote capture: ", @dbl_buffer);
        debug_fine("echo_call(): line after quote capture: ", $line)
    }
    $line = rws_line($line);
    @split_line = split / /,$line;
    foreach my $sub_line (@split_line) {
        debug_fine("In echo: sub_line:......", $sub_line);
        # substitute keys for original strings in correct order
        if (is_sgl_key($sub_line) || is_dbl_key($sub_line)) {
            $sub_line = recomplile_quotes($sub_line, \@sgl_buffer, \@dbl_buffer);

        }
        # argument variable case
        if ((is_arg($sub_line) && !is_sgl_quote($sub_line)) || is_dbl_quote_var($sub_line)) {
            $sub_line = arg_call($sub_line);
            push @buffer, $sub_line;
            push @buffer, ", ";
        # regular variable case
        } elsif ((is_variable($sub_line) && !is_sgl_quote($sub_line)) || is_dbl_quote_var($sub_line)) {
            $sub_line = variable_call($sub_line);
            push @buffer, "$sub_line";
            push @buffer, ", ";
        # regular case
        } else {
            if (is_sgl_quote($sub_line) || is_dbl_quote($sub_line)) {
                push @buffer, $sub_line;
                push @buffer, ", ";
            } else {
                push @buffer, "'$sub_line'";
                push @buffer, ", ";
            }
        }
    }
    # remove trailing ', '
    $buffer[-1] = "";
    push @TO_PRINT, join('', @buffer);
    debug("\nAfter echo_call():", @TO_PRINT);
}


sub assign_variable
{
    my $line = shift;
    my @buffer = split /=/,$line,2;
    $ASSIGNED_VAR{$buffer[0]} = 1 if (!exists($ASSIGNED_VAR{$buffer[0]}));
    if (is_variable($buffer[1])) {
        $buffer[1] =~ s/\$//;
        $buffer[2] = $buffer[1];
    } elsif (is_arg($buffer[1])) {
        $buffer[1] =~ s/\$//;
        $buffer[2] = "sys.argv[$buffer[1]]";
    } else {
        $buffer[2] = "'$buffer[1]'";
    }
    $buffer[1] = " = ";
    push @TO_PRINT, join('', @buffer);
    debug("\nAfter assign_variable():", @TO_PRINT);
}

sub rws_line
{
    my $line = shift;
    $line =~ s/ +/ /g;
    $line =~ s/^ | $//g;
    return $line;
}

###
# Subset 1
###

sub process_for
{
    my $line = shift;
    my @words = split / /,$line;
    # 2nd argument is new variable
    $ASSIGNED_VAR{$words[1]} = 1 if (!exists($ASSIGNED_VAR{$words[1]}));
    # first 3 arguments of for statement remain the same
    foreach $i (0..2) {
        $words[$i] = "$words[$i] ";
    }
    push @buffer, shift @words;
    push @buffer, shift @words;
    push @buffer, shift @words;
    foreach $word (@words) {
        if (is_number($word)) {
            push @buffer, $word;
            push @buffer, ", ";
        } elsif (is_glob($word)) {
            # update import hash
            $IMPORT{"glob"} = 1 if (!exists($IMPORT{"glob"}));
            # modify formatting to python std
            push @buffer, "sorted(glob.glob(\"";
            push @buffer, $words[0];
            push @buffer, "\"))";
            push @buffer, ":";
        } else {
            push @buffer, "'$word'";
            push @buffer, ", ";
        }
    }
    $buffer[-1] = ":";
    # add to print array as single element
    push @TO_PRINT, join('', @buffer);
    debug("\nAfter process_for():", @TO_PRINT);
}

sub os_call
{
    my $line = shift;
    my @buffer = ();
    # update import hash
    $IMPORT{"os"} = 1 if (!exists($IMPORT{"os"}));
    my @split_line = split / /,$line,2;
    # change directory case
    if (is_cd($line)) {
        # modify formatting to python std
        push @buffer, "os.chdir('";
        push @buffer, $split_line[1];
        push @buffer, "')";
    }
    # add to print array as single element
    push @TO_PRINT, join('', @buffer);
}

sub sys_call
{
    my $line = shift;
    # update import hash
    $IMPORT{"sys"} = 1 if (!exists($IMPORT{"sys"}));
    my @buffer = ();
    my @split_line = split / /,$line,2;
    # 'exit' case
    if (is_exit($line)) {
       # modify formatting to python std
       push @buffer, "sys.$split_line[0]($split_line[1])";

    # 'read' case
    } elsif (is_read($line)) {
        # arg 2 is a variable, update variable hash
        $ASSIGNED_VAR{$split_line[1]} = 1 if (!exists($ASSIGNED_VAR{$split_line[1]}));
        # modify formatting to python std
        push @buffer, $split_line[1];
        push @buffer, " = sys.stdin.readline().rstrip()";
    }
    # add to print array as single element
    push @TO_PRINT, join('', @buffer);

}

###
# Subset 2
###

sub arg_call
{
    my $line = shift;
    my @args = ();
    if (!is_sgl_quote($line) || (is_sgl_quote($line) && is_dbl_quote_var($line))) {
        while (is_arg($line)) {
            $IMPORT{"sys"} = 1 if (!exists($IMPORT{"sys"}));
            my $arg = $1 if ($line =~ /\$([\d]+)/);
            push @args, "sys.argv[$arg]";
            if (is_dbl_quote_var($line)) {
                $line =~ s/\$[\d]+/\%s/;
            } else {
                $line = $args[-1];
                debug("arg_call(): return value:......", $line);
                return $line;
            }

        }
    }
    $arg = join(', ', @args);
    if (is_dbl_quote($line)) {
        if (@args > 1) {
            $line = "$line % ($arg)";
        } else {
            $line = "$line % $arg";
        }
    } else {
        $line = $arg;
    }
    debug("arg_call(): return value:......", $line);
    return $line;
}

sub variable_call
{
    my $line = shift;
    my @vars = ();
    if (!is_sgl_quote($line) || (is_sgl_quote($line) && is_dbl_quote_var($line))) {
        while (is_variable($line)) {
            my $var = $1 if ($line =~ /\$([\w]+)/);
            push @vars, $var;
            if (is_dbl_quote($line)) {
                $line =~ s/\$[\w]+/\%s/;

            } else {
                $line =~ s/\$//;
                return $line;
            }

        }
    }
    $var = join(', ', @vars);
    if (is_dbl_quote($line)) {
        if (@vars > 1) {
            $line = "$line % ($var)";
        } else {
            $line = "$line % $var";
        }
    } else {
        $line = $var;
    }
    debug("variable_call(): return value:......", $line);
    return $line;

}

sub extract_quotes
{
    ($line, $Sgl_buffer, $Dbl_buffer) = @_;
    # capture single quote statement and insert key
    while (is_dbl_quote($line)) {
        $line =~ s/(\"[^"]+\")/ DBL_QUOTE / or die;
        push @$Dbl_buffer, $1;
    }

    while (is_sgl_quote($line)) {
        $line =~ s/(\'[^']+\')/ SGL_QUOTE / or die;
        push @$Sgl_buffer, $1;
    }

    return $line;
}

sub recomplile_quotes
{
    my ($line, $Sgl_buffer, $Dbl_buffer) = @_;

    while (is_sgl_key($line) | is_dbl_key($line)) {

        my @split_line = split / /,$line;
        foreach $word (@split_line) {
            if (is_not_empty($word)) {
                debug_fine("recompile_quotes(): in loop: word:", $word);
                if (is_sgl_key($word)) {
                    $word = shift @$Sgl_buffer;
                    debug_fine("recompile_quotes(): shift sgl quote string:", $word);

                } elsif (is_dbl_key($word)) {
                    $word = shift @$Dbl_buffer;
                    debug_fine("recompile_quotes(): shift dbl quote string:", $word);
                }
                # string space formatting
                $word = " $word" if (is_quotes($word) || is_word($word));
            } else {
                $word =~ s/ //;
            }
        }
        $line = join('', @split_line);
        $line = rws_line($line);
    }
    $line = remove_quote_key($line);
    return $line;
}

sub insert_quote_key
{
    my $line = shift;
    $line =~ s/"/ DBL /g;
    $line =~ s/'/ SGL /g;
    debug_fine("insert_quote_key(): line:", $line);
    return $line;
}

sub remove_quote_key
{
    my $line = shift;
    $line =~ s/ DBL | DBL$|^DBL /"/g;
    $line =~ s/ SGL | SGL$|^SGL /'/g;
    debug_fine("remove_quote_key(): line:", $line);
    return $line;
}


sub process_if
{
    my $line = shift;
    my @buffer = ();
    # if && elif case
    if (!is_else($line)) {
        my @split_line = split / /,$line;
        # first argument remains the same
        @buffer = shift @split_line;
        if (is_test($split_line[0])) {
            # remove test
            shift @split_line;
            # formatt remaining arguments
            foreach $s_line (@split_line) {
                $s_line = process_truth($s_line);
                push @buffer, $s_line;
            }
        }
    # else case
    } else {
        push @buffer, $line;
    }
    push @buffer, ":";
    push @TO_PRINT, join('', @buffer);
}

sub process_truth
{
    my $line = shift;
    if (is_variable($line)) {
        $line =  variable_call($line);
        $line = " $line"
    } elsif (is_arg($line)) {
        $line = arg_call($line);
        $line = " $line"
    } elsif (is_word($line)) {
        $line = " '$line'";
    } elsif ($line eq ('=' || '-eq')) {
        $line = " ==";
    } elsif ($line eq ('!=' || '-ne')) {
        $line = " !=";
    } elsif ($line eq ('<' || '-lt')) {
        $line = " <";
    } elsif ($line eq ('>=' || '-le')) {
        $line = " >=";
    } elsif ($line eq ('>' || '-gt')) {
        $line = " >";
    } elsif ($line eq ('>=' || '-ge')) {
        $line = " >=";
    } else {
        $line = " $line"
    }
    return $line;
}

###
# Print Functions
###

sub print_imports
{
    foreach $key (sort keys %IMPORT) {
        print "import $key\n";
    }
}

sub print_output
{
    debug("*****Final Output*****\n");
    my $indent_num = 0;
    $indent = "   ";
    print "$TO_PRINT[0]\n";
    shift @TO_PRINT;
    print_imports();
    while ($BLANK_LINES != 0) {
        print "\n";
        $BLANK_LINES--;
    }
    foreach $line (@TO_PRINT) {
        #print "Line....$line....\n" if ($DEBUG);
        if (is_done($line) || is_fi($line)) {
            debug_fine(".....In is_done print\n");
            $indent_num--;

        } elsif ($indent_num gt '0') {
            debug_fine(".....In \$in_for print\n");
            $i = 0;
            $indent_num-- if (is_else($line) || is_elif($line));
            while ($i < $indent_num) {
                print "$indent";
                $i++;
            }
            if (is_else($line) || is_elif($line) || is_for_loop($line) || is_if($line)) {
                $indent_num++;
            }
            print "$line\n";


        } elsif (is_for_loop($line)) {
            debug_fine(".....In is_for_loop print\n");
            print "$line\n";
            $indent_num++;

        } elsif (is_if($line)) {
            debug_fine(".....In is_if print\n");
            print "$line\n";
            $indent_num++;

        } else {
            debug_fine(".....In default print if\n");
            print "$line\n";
        }

    }
}

###
# Main Processing
###

sub process_line
{
    my $line = shift;
    #@for_buffer = ();
    # bash #! case
    if (is_bash($line, $.)) {
        push @TO_PRINT, "#!/usr/bin/python2.7 -u";

    } elsif (is_comment($line)) {
        push @TO_PRINT, $line;

    # variable assignment case
    } elsif (is_variable_assign($line)) {
        assign_variable($line);

    # echo case
    } elsif (is_echo($line)) {
        echo_call($line);

    # subprocess_call case(s) (ls | pwd | date | id)
    } elsif (is_subprocess($line)) {
        subprocess_call($line);

    # os_call case (cd)
    } elsif (is_os($line)) {
        os_call($line);

    # sys_call case (exit | read)
    } elsif (is_sys($line)) {
        sys_call($line);

    #} elsif (is_while_loop($line)) {
    #    process_while($line);

    # initial for loop case
    } elsif (is_for_loop($line)) {
        process_for($line);

    # indent structure cases
    } elsif (is_do($line) | is_then($line)) {
        #nothing
    } elsif (is_done($line)) {
        push @TO_PRINT, $line;

    # initial if case
    } elsif (is_if($line) | is_elif($line) | is_else($line)) {
        process_if($line);

    # if end case
    } elsif (is_fi($line)) {
        push @TO_PRINT, $line;
        debug_fine("\nafter push fi\n", @TO_PRINT);

    # Lines we can't translate are turned into comments
    } else {
        push @TO_PRINT, "#$line";
    }
}

############
#   Main   #
############

our @TO_PRINT = ();
our %ASSIGNED_VAR = ();
our %IMPORT = ();
our $BLANK_LINES = 0;

#input will be delimited by '\n' char
while ($line = <>) {
    chomp $line;
    # compress spaces && remove leading/trailing spaces
    if (is_not_empty($line)) {
        $line = rws_line($line);
    } else {
        $BLANK_LINES++;
    }
    if (is_not_empty($line)) {
        process_line($line);
    }
}
print_output();
