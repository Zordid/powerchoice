# Power-Choice User's Guide (1990)

*A transcription of the 14-page User's Guide that came in the Power-Choice
1.0e package of Softwhere Associates, so that it can be read and searched
online. The scan of the printed booklet is in
[users-guide.pdf](users-guide.pdf). The text follows the original, typos
included; the screen shots are written out as text, and page numbers are
given in brackets.*

---

**Softwhere Associates**

# Power-Choice

*The Ultimate Menu System*

**User's Guide**

---

## Table of Contents

| | |
|---|---:|
| Section I - Introduction | 1 |
| Section II - What is a Menu System ? | 1 |
| Section III - The Installation Process | 3 |
| Section IV - Getting Started | 4 |
| Section V - How to use Power-Choice | 11 |
| Section VI - Trouble-Shooting | 12 |

---

© Copyright 1990 Softwhere Associates

P.O.Box 2061, Evanston WY 82931-2061

**This software and documentation may only be used or available for use on
one machine at a time. You may not copy this software for any other purpose
than personal backup.**

**Site licenses are available. Please contact Softwhere Associates at the
address above for more information.**

---

## Section I - Introduction

*[page 1]*

Welcome to **Power-Choice**, the *Ultimate Menu System*! This brief manual
will help you with the installation process and the use of
**Power-Choice**. For your convenience, it is divided into 5 sections.
Section II covers the basic components of a menu system, Section III and IV
however will explain how to use and install **Power-Choice** in detail so
you can cut down your work to a keypress ! We hope you will enjoy
**Power-Choice** !

## Section II - What is a Menu System ?

A Menu System enables you to choose the program you wish to activate
without having to remember long and complicated DOS commands. Once you have
the menu set up, one keypress will start up the desired program. After the
installation and setup of your menu, you will be presented with the
selection screen every time you start your computer.

Several programs of the same type should be arranged in separate groups,
whereas groups are arranged in a "tree structure" descending from the Main
Group. (see diagram on the next page)

*[page 2]*

```
Main Group
  ├──► Desktop Publishing Group
  │      ├──► Ventura Publisher (Program)
  │      └──► GEM Desktop (Program)
  ├──► Word Processing Group
  │      ├──► WordPerfect 5.0 (Program)
  │      └──► MS-Word 4.0 (Program)
  └──► Software Tools Group
         ├──► PCTools Deluxe 4.21 (Program)
         └──► XTree Pro Gold (Program)

Sample diagram of a menu structure . . .
```

You have to start building your structure from the Main Group down to the
individual programs. To change groups, simply point at the new group and
hit Enter. The term "Parent Group" refers to the group from which the
current group originated. (The Main Group does not have a Parent Group !)
For example, in the diagram above, the Main Group is the Parent Group of
the Word Processing Group. To return to the Parent Group simply press Tab.
Any group can branch to another group as well as contain items that
actually refer to programs.

## Section III - The Installation Process

*[page 3]*

To install **Power-Choice** on your harddisk, just follow these few, simple
steps !

- Put the **Power-Choice** disk in any drive.
- At the DOS prompt change to the drive you put the disk in by typing A: or
  B: and hit Enter.
- Type PCHINST and press Enter.
- The installation program will then offer a choice between "Easy" and
  "Custom" installation. Easy installation will install **Power-Choice** in
  C:\PCHOICE, update your AUTOEXEC.BAT file and reboot the computer
  automatically by asking you a minimum number of questions, whereas Custom
  installation allows you to change the defaults and paths individually.
  Either one will suffice.

NOTE: The built-in screen saver that prevents monitors from burning in,
only works with Hercules Monochrome cards, CGA graphics cards and some EGA
cards. For that reason you will not even be asked whether you want to
enable the screen saver if you have a VGA card. If the screen saver creates
problems with the screen display, reinstall **Power-Choice** not using the
screen saver at all!

*[page 4]*

```
05/18/90     * * *  P O W E R - C H O I C E  Ver 1.0e  * * *     5:00:07 pm

                 ┌ Main Group ──────────────────────────┐
                 │ A» Desktop Publishing Group          │
                 │ B» Math Group                        │
                 │ C» Accounting Group                  │
                 │ D» Software Tools Group              │
                 │ E» Softwhere Associates              │
                 └──────────────────────────────────────┘

This is the Desktop Pulishing Group with programs like Ventura, etc.
                                                     ┤ 400 KB Memory free ├
Use ↑↓ to choose. Enter-Run, F2-Edit, Esc-DOS        (C) Softwhere Associates
```

## Section IV - Getting started

Please read all of this section carefully before continuing your
installation !

After the installation process, a reboot is necessary. (If you choose
"Easy Installation", this will be done automatically !) After a few
seconds, **Power-Choice** will appear, showing you the (still) empty Main
Group. **Power-Choice** displays the current group in the middle of the
screen and a key/function description at the very bottom of the screen
which displays all the options available.

*[page 5]*

Before customizing your menu structure it is wise to consider the Main
Group components as well as all programs you want to incorporate. Make a
short list of programs and how to load them. For example if you want to
install a program called TEST, you need to know the path where it resides
and the command to start it. Having finished your list, press **F2** to
enter the Edit Mode. You will be presented with a list of operations
available.

### The Edit Mode

```
05/18/90     * * *  P O W E R - C H O I C E  Ver 1.0e  * * *     5:00:28 pm

  ┌ Edit Mode ─────────┐      ┌ Main Group ────────────────────────────┐
  │ Change Menu Item   │      │ A» Desktop Publishing Group            │
  │ Insert Menu Item   │      │ B» Math Group                          │
  │ Delete Menu Item   │      │ C» Accounting Group                    │
  │ ────────────────── │      │ D» Software Tools Group                │
  │ Change Passwords   │      │ E» Softwhere Associates                │
  │ Rearrange Group    │      └────────────────────────────────────────┘
  │ Save Menu file     │
  │ ────────────────── │
  │ Undo last change   │
  │ Reset Menu         │
  │ ────────────────── │
  │ Quit Edit Mode     │
  └────────────────────┘
                                                     ┤ 400 KB Memory free ├
Use ↑↓ to choose, Enter-Select                       (C) Softwhere Associates
```

*Change Menu Item* - Is used to change a single menu item within the
current group. You will be prompted to select the item you want to change.
You will work within an entry screen that will be described later.

*[page 6]*

*Insert Menu Item* - Is used to introduce a new item to the current page.
After selecting the new position, then choose between "Command Item" or
"Group Item". If you select "Command Item" you create an item that calls a
single program. "Group Item", will create a new, empty group. In order to
insert items in this new group, however it is necessary to leave the Edit
Mode by pressing Esc and change to the new group (Highlight it and press
Enter). Then press **F2** to return to Edit Mode !

*Delete Menu Item* - Is used to delete an item out of the current group.
Just highlight the desired item and confirm by pressing "Y".
NOTE: You cannot delete group items that refer to groups that are not
empty.

*Change Passwords* - To define/change a Log-On password, a DOS password and
an Edit password, use this option. If you want to define a Log-On or DOS
password, it is advisable to define an Edit password also, as otherwise the
access to this option is not restricted.

*Rearrange Group* - If you want to rearrange the order of the items within
a group, choose this option. Then select the item to move and place it
wherever you desire. The lettering will be automatically adjusted.

*[page 7]*

*Save Menu File* - Usually not used, as every change will try to save
automatically. In case of I/O-error though, it is possible to abort and
save later after correcting the mistake.

*Undo Last Change* - In case of an unwanted change, it is possible to undo
only the very last change that you made. (This can be very useful !)

*Reset Menu* - **CAUTION** - This function will totally destroy your menu
structure. Thus it is necessary to type **YES** before anything will be
done. Use this function only to start from scratch !!

*Quit Edit Mode* - Returns you to the menu... (Esc does the same thing !)

### The Item Entry Screen

*[page 8]*

This screen will appear when you change or insert an item. If the item is
a command item, it will look like this:

```
05/18/90     * * *  P O W E R - C H O I C E  Ver 1.0e  * * *     5:02:15 pm

  ┌ Edit Mode ─────────┐      ┌ Desktop Publishing Group ──────────────┐
  │ Change Menu Item   │      │ A» Ventura Publisher /w Softkicker     │
  │ Insert Menu Item   │      │ B» WordPerfect 5.1                     │
  │ Delete Menu Item   │      │ C» Harvard Graphics                    │
  │ ────────────────── │      │ D» Harvard Graphics Draw Partner       │
  │ Chan┌ Edit Command Item ─────────────────────────────────────┐
  │ Rear│ Item No. : A                                           │
  │ Save│ Name     : Ventura Publisher /w Softkicker.........    │
  │ ────│ Message  : Ventura Publisher 2.0 with Softkicker...    │
  │ Undo│ Password : VENT......                                  │
  │ Rese│ Path     : D:\.....................................    │
  │ ────│ Commands : call skprof.............................    │
  │ Quit│ Clock ?  : No              Wait ?   : Yes              │
  │ ────└────────────────────────────────────────────────────────┘
  └────────────────────┘
                                                     ┤ 400 KB Memory free ├
Use ←↑↓→ to move. F10-Save, Esc-Cancel               (C) Softwhere Associates
```

For group items, the window will look like this:

```
05/18/90     * * *  P O W E R - C H O I C E  Ver 1.0e  * * *     5:00:40 pm

  ┌ Edit Mode ─────────┐      ┌ Main Group ────────────────────────────┐
  │ Change Menu Item   │      │ A» Desktop Publishing Group            │
  │ Insert Menu Item   │      │ B» Math Group                          │
  │ Delete Menu Item   │      │ C» Accounting Group                    │
  │ ────────────────── │      │ D» Software Tools Group                │
  │ Chan┌ Edit Group Item ───────────────────────────────────────┐
  │ Rear│ Item No. : A                                           │
  │ Save│ Name     : Desktop Publishing Group...............     │
  │ ────│ Message  : This is the Desktop Pulishing Group with→   │
  │ Undo│ Password : SECRET....                                  │
  │ Rese└────────────────────────────────────────────────────────┘
  │ ────────────────── │
  │ Quit Edit Mode     │
  └────────────────────┘
                                                     ┤ 400 KB Memory free ├
Use ←↑↓→ to move. F10-Save, Esc-Cancel               (C) Softwhere Associates
```

*[page 9]*

Use the cursor keys to move around within the screens.
Put the name of the item as you want it to appear later in the "Name"
category.
The "Message" category is used to define a message (up to 80 characters
long) that will appear at the bottom of the screen when the item is
highlighted.
You may also enter an optional password that will be asked for before any
operation with the item is done (This includes Change, Delete and Execute
it). So don't forget the password !
If you are editing a command item you also have to enter the path in which
the program resides, as well as the DOS commands necessary to run it. For
example:
To run the program "TEST" on drive C: , you used to type
"CD \TESTDIR\DEMO" and "TEST". Now you put "C:\TESTDIR\DEMO" into the
"Path" category and "TEST" in the "Command" category.
If a program requires several commands to run, you have to separate the
commands with the ASCII sign 179 (Hold the Alt-key down and enter 1 7 9 on
the keypad)
If your program (TEST, for example) runs in text mode most the time (i.e.
uses no graphics), you might want to have a clock in the upper right corner
of the screen at all time. To do this, just put a "Y" behind the "Clock ?"
statement.
Some programs leave important messages on the screen when they terminate.
To give you time to read this, you *[page 10]* can force **Power-Choice**
to wait before returning to the menu screen. Just put a "Y" behind the
"Wait ?" statement!

When you are finished editing the entry screen, press **F10** to save your
changes or Esc to discard them. Several messages may appear when you press
**F10** to save:
"Specified path not found" indicates that the path you specified in the
entry screen does not exist.
"No commands to execute are specified" indicates that you left the command
line blank. In both cases it is recommendable to use "Change Item" to
correct the mistake.

NOTE: If any problems occur while saving, try to correct the cause
immediately or, if not possible, later. But then don't forget to use the
"Save Menu" function or all your changes will be lost !

**Important!**
If the program has to be started with a batch file (extension .BAT), it is
necessary to type CALL NAME.BAT where NAME stands for the filename.
Otherwise the menu will not return when you exit the program.

### The Password Entry Screen

*[page 11]*

```
05/20/90     * * *  P O W E R - C H O I C E  Ver 1.0e  * * *     2:43:41 pm

  ┌ Edit Mode ─────────┐      ┌ Main Group ────────────────────────────┐
  │ Change Menu Item   │      │ A» Desktop Publishing Group            │
  │ Insert Menu Item   │      │ B» Mathematics  Group                  │
  │ Delete Menu Item   │      │ C» Accounting Group                    │
  │ ────────────────── │      │ D» Software Tools Group                │
  │ Change Passwords   │      │ E» Softwhere Associates                │
  │ Rearrange Group    │      └────────────────────────────────────────┘
  │ Save Menu file     │
  │ ────────────────── │   ┌ Change Passwords ──────────────┐
  │ Undo last change   │   │ Log On Password  : HELLO.....  │
  │ Reset Menu         │   │ Edit Password    : CHANGE....  │
  │ ────────────────── │   │ DOS Password     : EXIT......  │
  │ Quit Edit Mode     │   └────────────────────────────────┘
  └────────────────────┘
                                                     ┤ 367 KB Memory free ├
Use ←↑↓→ to move. F10-Save, Esc-Cancel               (C) Softwhere Associates
```

This screen only appears when you select "Change Passwords". Again, use the
cursor keys to move and press **F10** to save or Esc to discard when you're
finished !

## Section V - How to use Power-Choice

Once you've installed all of your favorite programs in the menu structure,
you can leave the Edit Mode and enjoy the convenience of **Power-Choice**.

To choose from your menu, simply highlight the desired item or press the
associated key. (A, B, C, ...) Use the Tab key to return to the parent
group.

*[page 12]*

If you want to exit **Power-Choice** to enter DOS commands, press Esc.
**Power-Choice** will then return to the DOS prompt, with a clock in the
upper right corner. To reenter **Power-Choice**, type PCH at any time.
NOTE: Whenever the clock is displayed (during DOS shell or <u>any</u> other
program) you can press **Left-Ctrl + Left-Alt + Right-Shift** to disable
it. To enable, press the same keys!
If you have installed the screen saver, it will switch off the display
every 3 minutes if there was no keypress, mouse movement or any other
serial communication. To switch on the display again, simply press any key!

Anytime you purchase a new program, be sure to include it into your
**Power-Choice** menu. And remember: **Power-Choice** is flexible ! If you
don't like the way you set up your structure, change it. It's that simple !!

## Section VI - Trouble-Shooting

This is a short list of problems that might occur. Please read this section
if you have any problems before consulting Softwhere Associates for help.

The first part of the table explains general problems that might occur when
using **Power-Choice**, the second part describes **Power-Choice's** error
messages.

*[page 13]*

| Problem | What you can do |
|---|---|
| Little dots in the upper right corner of the screen | Try running the program with the clock set to "off" |
| The screen display flickers and is illegible | Reinstall Power-Choice without the screen saver. |
| The Power-Choice menu does not return when you quit your program | The file you put in the "command" category is a batch file and requires a "CALL" in front of it. |

| Message | What you can do |
|---|---|
| Menu file not found or destroyed | Power-Choice could not read the menu file PCHOICE.MNU. You have to rebuild your menu from scratch. |
| Menu file could not be written to disk | I/O-Error caused trouble. Try to fix the disk and use Save Menu to save. |
| Disk full! Menu file was not written to disk | Exit Power-Choice and make room on your harddisk ! |
| Backup file for UNDO could not be saved | I/O-Error caused trouble. Try to fix the disk. You won't be able to use UNDO! |
| UNDO unsuccessful ! Backup file not found | No backup file exists, nothing you can do ! |
| Batch file could not be modified | I/O-Error caused trouble, nothing you can do. |
| No commands to execute are specified | You edited a command item and did not specify any commands. |
| *[page 14]* Specified path does not exist | You edited a command item and the specified path cannot be accessed. |
| Item refers to a group that is NOT empty | You cannot delete the item because the group it refers to is not empty. |
| Group contains only one item | You tried to rearrange a group with only one item. |
