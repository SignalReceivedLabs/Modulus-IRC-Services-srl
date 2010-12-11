# Project To-Do List

## Core

* Make everything event-driven
* Protocol Interoperability
* Localization Support
* On-Protocol Help
* Encrypted Passwords
* Command and message hooks should use Events
* Dynamic code (re)loading
* Configuration rehashing

### Protocol Support

* Bahamut
* Charybdis
* DreamForge
* Hybrid
* ircu
* InspIRCD
* IRCD
* Nefarius IRCu
* PleXusIRCd
* PTLink
* Ratbox
* ShadowIRCD
* SolidIRCd
* UnrealIRCD (In Progress) *3.2.8.10 or with ESVID patch*
* UltimateIRCd

## Modules

* Move commands to individual files

### NickServ

* Drop
* Identify
* Info
* Ghost
* Noexpire
* Note
* Suspend
* Unsuspend
* Forbid
* Unforbid
* Vacation
* Unvacation

### ChanServ

* Register
* Drop
* List
* Grant
* Ungrant
* Topic
* Kick
* Ban
* Unban
* Forbid
* Unforbid
* Mode
* Invite
* Store grants in boolean columns rather than the dumb string

### OperServ

* Quit
* Restart
* Rehash
* ReloadMod
* LoadMod
* UnloadMod
* DropAccount
* AddAccount
* ListAccounts
* Global

### HostServ

* Set command for other users for services administrators
* Allow different characters depending on protocol or configuration. Not really sure how to do that yet.

### BotServ

* Create
* Delete
* Join
* Part
* Say
* Act
* Forbid
* Unforbid
* Grant
* Ungrant

### LogServ

* Join
* Part
* Age
* Get
* Delete

### BanServ

* Akill
* RegexKill

### MemoServ

* Send
* Draft
* Inbox
* Outbox
* Sent
* Drafts
* Read
* Delete

### SpamServ

* Join
* Part
* Badwords
* Colors
* Formatting
* Limit
* Punishment

### NoteServ

* Add
* Read
* Delete

### PollServ

* Add
* Send
* List
* Delete
* Auto

### BuddyServ

* Add
* Remove
* List
* Broadcast

### QuoteServ

* Add
* Remove
* Search
* Get
* Join
* Part
