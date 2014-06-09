evernote-jeeves
===============

This command-line Ruby script searches for a given search string S in all notes updated in the last N days,
and displays all lines containing that search string, along with some useful note and folder context metadata. 

Use Case
========

I use Evernote all day long at work, sometimes making a dozen notes in a day.  I've developed a TODO habit, 
where I'll write something like this in a note:

TODO Follow-up with Bob regarding the FY15 budgets

Problem is, at the end of the day or week, I'll have to hunt back through all of my notes to find my TODOs. 
So I wrote a script to help.

Usage
=====

Usage: jeeves.rb [options]
    -v, --verbose                    Run verbosely
    -s, --search s                   Search string to look for in notes.
    -d, --days N                     Number of days in the past to search.
    -h, --help                       Show this message

$ ruby jeeves.rb -d 7 -s TODO
Budget Meeting (06/09/14, Finance)
  TODO Follow-up with Bob regarding the FY15 budgets

Team Dev Meeting (06/05/14, IT)
  TODO Renew RubyMine licenses
  TODO Check on RailsConf expense reports

1:1 with James (06/04/14, Supervision)
  TODO Establish backup on-call plan during James' vacation
  
Known Issues
============

The search is case-insensitive, because that's the way Evernote does it.  However, the matching is case-sensitive,
so it's possible to get a note with no matching lines displayed (e.g. you search "DONE", will match but not display
lines with "done").  I'll fix this someday.

Software not generally ready for distribution (no Gemfile, no VERSION, etc... etc...)


