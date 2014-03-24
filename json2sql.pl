#! /usr/bin/perl

print <<'EOS';
\echo ###### Prepare for the test
\set QUIET
SET client_min_messages = 'error';
CREATE EXTENSION IF NOT EXISTS pg_store_plans;
DROP TABLE IF EXISTS plans;
CREATE TABLE plans (id int, title text, lplan text, splan text);
SET client_min_messages = 'notice';
\set ECHO none

\echo ###### insert original JSON plans
INSERT INTO plans (VALUES
EOS

$plan_no = 0;
$title = "###### Plan $plan_no: all properties";
setplan0();
print "($plan_no, \'$title\',\n";
print " $escape'$plan')";

$plan_no++;
$state = 0;
while(<>) {
	chomp;
	if ($state == 0) {
		next if (!/^###### (.*$)/);
		$title = "###### Plan $plan_no: $1";
		$state = 1;
	} elsif ($state == 1) {
		if (/[}\]:,]/) {
			die("??? : $_");
		}
		next if (!/^   { *\+$/);
		$plan = $_;
		$plan =~ s/^   (.*[^ ]) *\+$/$1\n/;
		$state = 2;
	} elsif ($state == 2) {
		if (/^   } *\+$/) {
			$state = 3;
		}
		$l = $_;
		$l =~ s/^   (.*[^ ]) *\+$/$1/;
		$plan .= "$l";
		$plan .= "\n" if ($state == 2);
	} elsif ($state == 3) {
		$escape = "";
		if ($plan =~ /'/ || $plan =~ /\\\"/) {
			$escape = "E";
		}
		# Add escape char for '''
		$plan =~ s/'/\\'/g;
		# Add escape char for '\"'
		$plan =~ s/\\\"/\\\\\"/g;

		# Remove "Total Runtime" line.
		$plan =~ s/,\n *"Total Runtime":.*\n/\n/;
		
		print ",\n($plan_no, \'$title\',\n";
		print " $escape'$plan')";
		$plan_no++;
		$state = 0;
	}
}

print <<'EOS';
);

\pset pager
\set ECHO queries

\echo ###### set shortened JSON
UPDATE plans SET splan = pg_store_plans_shorten(lplan);

\echo ###### JSON properties round-trip test
SELECT id FROM plans
	where pg_store_plans_jsonplan(splan) <> lplan;

\pset format unaligned
\pset tuples_only on
\pset recordsep '\n\n=======\n'
\echo  ###### format conversion tests
SELECT '### '||'yaml-short       '||title||E'\n'||
  pg_store_plans_yamlplan(splan)
  FROM plans WHERE id BETWEEN 1 AND 3 or id = 1 ORDER BY id;
\echo  ################## 
SELECT '### '||'xml-short        '||title||E'\n'||
  pg_store_plans_xmlplan(splan)
  FROM plans WHERE id BETWEEN 4 AND 6 or id = 1 ORDER BY id;

\echo  ###### text format output test
SELECT '### '||'TEXT-short       '||title||E'\n'||
  pg_store_plans_textplan(splan)
  FROM plans ORDER BY id;

\echo  ###### long-json-as-a-source test
SELECT '### '||'yaml-long JSON   '||title||E'\n'||
  pg_store_plans_yamlplan(lplan)
  FROM plans WHERE id = 1 ORDER BY id;
\echo  ################## 
SELECT '### '||'xml-long JSON    '||title||E'\n'||
  pg_store_plans_xmlplan(lplan)
  FROM plans WHERE id = 1 ORDER BY id;
\echo  ################## 
SELECT '### '||'text-long JSON   '||title||E'\n'||
  pg_store_plans_xmlplan(lplan)
  FROM plans WHERE id = 1 ORDER BY id;

\echo  ###### chopped-source test
SELECT '### '||'inflate-chopped  '||title||E'\n'||
  pg_store_plans_jsonplan(substring(splan from 1 for char_length(splan) / 3))
  FROM plans WHERE id BETWEEN 16 AND 18 ORDER BY id;
\echo  ################## 
SELECT '### '||'yaml-chopped     '||title||E'\n'||
  pg_store_plans_yamlplan(substring(splan from 1 for char_length(splan) / 3))
  FROM plans WHERE id BETWEEN 19 AND 21 ORDER BY id;
\echo  ################## 
SELECT '### '||'xml-chopped      '||title||E'\n'||
  pg_store_plans_xmlplan(substring(splan from 1 for char_length(splan) / 3))
  FROM plans WHERE id BETWEEN 22 AND 24 ORDER BY id;
\echo  ################## 
SELECT '### '||'text-chopped     '||title||E'\n'||
  pg_store_plans_textplan(substring(splan from 1 for char_length(splan) / 3))
  FROM plans WHERE id BETWEEN 25 AND 27 ORDER BY id;

\echo ###### shorten test
SELECT '### '||'shorten          '||title||E'\n'||
  pg_store_plans_shorten(lplan)
  FROM plans WHERE id = 0 ORDER BY id;
\echo ###### normalize test
SELECT '### '||'normalize        '||title||E'\n'||
  pg_store_plans_normalize(lplan)
  FROM plans WHERE id BETWEEN 1 AND 3 ORDER BY id;

EOS

sub setplan0 {
	$plan = << 'EOS';
{
  "Plan": 0,
  "Plans": 0,
  "Node Type": "Result",
  "Node Type": "ModifyTable",
  "Node Type": "Append",
  "Node Type": "Merge Append",
  "Node Type": "Recursive Union",
  "Node Type": "BitmapAnd",
  "Node Type": "BitmapOr",
  "Node Type": "Seq Scan",
  "Node Type": "Index Scan",
  "Node Type": "Index Only Scan",
  "Node Type": "Bitmap Index Scan",
  "Node Type": "Bitmap Heap Scan",
  "Node Type": "Tid Scan",
  "Node Type": "Subquery Scan",
  "Node Type": "Function Scan",
  "Node Type": "Values Scan",
  "Node Type": "CTE Scan",
  "Node Type": "Workable Scan",
  "Node Type": "Foreign Scan",
  "Node Type": "Nested Loop",
  "Node Type": "Merge Join",
  "Node Type": "Hash Join",
  "Node Type": "Materialize",
  "Node Type": "Sort",
  "Node Type": "Group",
  "Node Type": "Aggregate",
  "Node Type": "WindowAgg",
  "Node Type": "Unique",
  "Node Type": "Hash",
  "Node Type": "SetOp",
  "Node Type": "LockRows",
  "Node Type": "Limit",
  "Parent Relationship": "Outer",
  "Parent Relationship": "Inner",
  "Parent Relationship": "Subquery",
  "Parent Relationship": "Member",
  "Parent Relationship": "InitPlan",
  "Parent Relationship": "SubPlan",
  "Scan Direction": "Backward",
  "Scan Direction": "NoMovement",
  "Scan Direction": "Forward",
  "Index Name": 0,
  "Relation Name": 0,
  "Function Name": 0,
  "CTE Name": 0,
  "Schema": 0,
  "Alias": 0,
  "Output": "[]",
  "Merge Cond": "a",
  "Strategy": "Plain",
  "Strategy": "Sorted",
  "Strategy": "Hashed",
  "Join Type": "Inner",
  "Join Type": "Left",
  "Join Type": "Full",
  "Join Type": "Right",
  "Join Type": "Semi",
  "Join Type": "Anti",
  "Command": "Intersect",
  "Command": "Intersect All",
  "Command": "Except",
  "Command": "Except All",
  "Sort Method": "top-N heapsort",
  "Sort Method": "quicksort",
  "Sort Method": "external sort",
  "Sort Method": "external merge",
  "Sort Method": "still in progress",
  "Sort Key": "a",
  "Filter": "a",
  "Join Filter": "a",
  "Hash Cond": "a",
  "Index Cond": "a",
  "TID Cond": "a",
  "Recheck Cond": "a",
  "Operation": "Insert",
  "Operation": "Delete",
  "Operation": "Update",
  "Subplan Name": "a",
  "Triggers": 0,
  "Trigger": 0,
  "Trigger Name": 0,
  "Relation": 0,
  "Constraint Name": 0,
  "Function Call": 0,
  "Startup Cost": 0,
  "Total Cost": 0,
  "Plan Rows": 0,
  "Plan Width": 0,
  "Actual Startup Time": 0,
  "Actual Total Time": 0,
  "Actual Rows": 0,
  "Actual Loops": 0,
  "Heap Fetches": 0,
  "Shared Hit Blocks": 0,
  "Shared Read Blocks": 0,
  "Shared Dirtied Blocks": 0,
  "Shared Written Blocks": 0,
  "Local Hit Blocks": 0,
  "Local Read Blocks": 0,
  "Local Dirtied Blocks": 0,
  "Local Written Blocks": 0,
  "Temp Read Blocks": 0,
  "Temp Written Blocks": 0,
  "I/O Read Time": 0,
  "I/O Write Time": 0,
  "Sort Space Used": 0,
  "Sort Space Type": "Disk",
  "Sort Space Type": "Memory",
  "Peak Memory Usage": 0,
  "Original Hash Batches": 0,
  "Hash Batches": 0,
  "Hash Buckets": 0,
  "Rows Removed by Filter": 0,
  "Rows Removed by Index Recheck": 0,
  "Time": 0,
  "Calls": 0
}
EOS
	chop $plan;
}
