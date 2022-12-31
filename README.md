# OrgPrez

A Godot presentation tool based on emacs [org-mode](https://orgmode.org/) files

I use this to make programming-related youtube videos such as [Dealing Cards in J](https://www.youtube.com/watch?v=eXGKK8BkCkg).

# Concept

- write a script for your presentation using emacs org-mode file
- this tool lets you record an edit one audio clip for each line of text
- then play back the whole thing as a godot animation and record the presentation with something like [OBS studio](https://obsproject.com/)
- you can also schedule custom godot scripts and animations with lines starting with `@`
- can also work with [jprez](https://github.com/tangentstorm/jprez) to make scripted presentations in a colorful REPL for the [J programming language](https://www.jsoftware.com/#/README)

# example "screenplay"

(I call the `.org` file a screenplay rather than a "script" because my videos tend to revolve around writing "scripts" in various programming languages.)

```org
#+title: video title (orgprez reads this but does nothing with it)

* asterisks indicate headlines
#+begin_src j
NB. 'src' blocks can contain text that you want
NB. to appear in a rich text editor node. currently
NB. orgprez knows how to syntax-highlight J code.
+/i.10
#+end_src

Text lines indicate words to be spoken by the narrator.

: NB. Lines starting with a colon generally appear in an on-screen REPL.

: NB. (actually, they just get sent to a godot function so you can override this)

: . ?a dot after the colon indicates a keyboard recording so you can animate typing?

: . ?note that this currently only works with jprez?

* orgprez headlines are usually not nested (though they can be)
#+scene: intro

This is the next slide. The 'scene' line tells orgprez to switch to this scene in its "slide deck".

The name corresponds to a godot '.tscn' file.

If that file has an AnimationPlayer node, OrgPrez will play an animation named 'init' every time you switch to this slide.

@play('other-animation')

Lines starting with an at-sign are passed to "command handler" methods in godot.

The line above calls the method call `cmd_play('org-animation')`.

By default, this method is called on the generic OrgPrez player,

but you can override any command by declaring your own gdscript method on your scene's root node.

```



# Requirements

Developed with with Godot 3.5 ... May work with 3.x ... Not yet ready for 4.0.

Needs installation of [godot-waveform](https://github.com/tangentstorm/godot-waveform).

Here's how I set it up on windows, since I don't have either of these repos published in the godot asset directory yet:

```powershell
# in powershell (running as admin to make the symlink)
cd d:/ver
git clone https://github.com/tangentstorm/godot-waveform
git clone https://github.com/tangentstorm/orgprez
cd orgprez/addons
New-Item -ItemType SymbolicLink -Path waveform -Target D:\ver\godot-waveform\addons\waveform\
```

# Working with JPrez

Getting the JPrez integration currently involves compiling some godot plugins with rust and setting up a bunch of symlinks. [see notes here](https://github.com/tangentstorm/j-talks/tree/master/addons).

I don't really expect anyone else to want to do this, so it's not likely to get easier anytime soon. But, if you are actually interested, please get in touch.
