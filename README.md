# ARCSHELL

ArcShell is a shell scripting, automation, and monitoring framework created by [Ethan Post](https://www.linkedin.com/in/ethanraypost/). 

It supports both Bash and Korn shells and contains more than [30 modules](https://github.com/arclogicsoftware/arcshell/tree/master/docs) that help you build amazing solutions. It can be up and running in a few minutes of time.

ArcShell is unique and unlike other Bash frameworks. It is meant to be used as a highly flexible distributed automation and monitoring development platform within enterprise IT scale environments. 

Please join the [announcements](https://groups.google.com/forum/#!forum/arcshell-announcements) and [support](https://groups.google.com/forum/#!forum/arcshell) email lists for updates. I am on  [Twitter](https://twitter.com/poststop). Email me here Ethan@ArclogicSoftware.com. Chat channels will be created when needed.

Documentation and updates uploaded every week. Most of it will be available before the end of May 2019. 

![arcshell_checklist_banner.jpg](./docs/images/arcshell_checklist_banner.jpg)

Icons designs by SmashIcons and available from [Flaticon](https://www.flaticon.com/packs/essential-collection).

## BEFORE YOU START

Please read this. These points will get you oriented with the product and reduce some of the frustration we all exerience when learning something new.

**My Development Environment:** ArcShell is developed in Bash using [Sublime Text](https://www.sublimetext.com/) on Windows. File system is shared to a [VirtualBox](https://www.virtualbox.org/) [Ubuntu](https://www.ubuntu.com/) host. If you watch any of the videos you will see this.

**Prerequisites:**  ArcShell should have very few if any prerequisites to get up and running. Depending on your environment you may need to install programs like awk or nawk, sed, bc, and perl. 

**Email:** It is recommended that your servers have outbound email capability. If native email support is not already configured I suggest you try SendGrid which is very easy to configure in ArcShell. If you need another option let us know.

**SSH:** It is also recommended that the servers you are working with support SSH connections. ArcShell can help you manage these connections.

**Primary vs. Remote Nodes:** ArcShell is typically maintained on a single node and then deployed to your remote nodes. ArcShell basically deploys a copy of itself. There are a lot of ways to tackle the deployment tasks. 

**Loading ArcShell:** After you install ArcShell you will need to load the framework into your command line environment or into your scripts. This is done using the file shown here.
```
# Load ArcShell like this. This file is re-created anytime you run setup.
. ${HOME}/.arcshell
# It will only load once. To force a re-load set arcHome to nothing.
arcHome=
. ${HOME}/.arcshell
```

**Truthy values:** ArcShell makes use of something called truthy variables. A lot of the configuration variables can be set to truthy values. These might look like this. 
```
# A limited range of cron expressions are allowed.
foo="* * * * *"
# 1 is true, 0 false.
bar=1
# Most forms or True/False,Yes/No are allowable.
foo="y"
```
Look at the arcshell_cron.sh module for more but keep this in mind when you start to configure the framework.

**ArcShell Homes:** There are three ArcShell homes.

| Name| Path| About | 
| ---- | ---- | ---- |
| Delivered | ${arcHome} | This is the directory ArcShell is installed in.
| Global | ${arcHome}/global or ${arcGlobalHome} | This is the directory where you will make 99% of your changes and where your files go. This directory is distributed to your other nodes.
| User | ${arcHome}/user or ${arcUserHome} | This directory is not distributed to the other nodes. If you need a file which is part of ArcShell but stays on a single node, this is where it will go.

We will see how these can be used later.

**Disk Space:** ArcShell doesn't take up much space initially. However, data collection tasks will eventually require more. You should have at least 2-4 Gigabytes of space available for an ArcShell installation.

**Configuration:** The two main configuration files are arcshell.cfg and setup.cfg. 

| File| About| 
| ---- | ---- |
| ./config/arcshell/arcshell.cfg | Can be present in any of the three ArcShell homes. Is loaded (and run) whenever you load the ${HOME}/.arcshell file. All files are loaded in top-down order. Delivered, Global, then user.|
| ./config/arcshell/setup.cfg | Can be present in any of the three ArcShell homes. Is loaded (and run) whenever you run setup. All files are loaded in top-down order. Delivered, Global, then user. |

**The Daemon:** The script which acts as the daemon is ```${arcUserHome}/arcshell.sh```. This file also gets rebuilt each time you run setup. Run ```arcshell.sh -help``` for some help on starting and stopping the daemon process. 

Add a job to your cron calling ```arcshell.sh -autostart``` to make sure to start ArcShell is started between server reboots if it was running prior to the event.

**Configuration Objects:** ArcShell has a powerful configuration file structure. These are just a some of most common ones.

In each case below the configuration can exist in one or more of the three ArcShell homes. In some cases only the first file found is loaded and in others all three files are loaded in order. This is dependent on the code making use of these items. We will learn more as we begin to make use of them.

| Location| About| 
| ---- | ---- |
| ./config/arcshell | Stores the archell.cfg and setup.cfg files. | 
| ./config/keywords | Keywords are used to route messages to different delivery mechanisms. For example "warning" may send email but not send  an SMS message. |
| ./config/contact_groups | Contact groups determine who messages go to, how they get there, and when. They are very powerful and yet very easy to configure. |
| ./config/alert_types | Alert types set up recurring notifications. Each alert type has two phases of alerting which can be configured. |
| ./schedules | This folder contains scheduled tasks which are just .sh scripts. ArcShell provides a number of out-of-the-box solutions. You can also create your own schedules and add your scripts to them. |


## INSTALLING ARCSHELL

| # | Title | Length |
| --- | --- | --- |
| 2.1 | How To Install ArcShell | [7 min](https://www.screencast.com/t/ZMM3atkq7) |
| 2.2 | Configure The 'arcshell.config' File | [5 min](https://www.screencast.com/t/IqedSmtRemG) |
| 2.3 | Configure The 'admins' Contact Group | [6 min](https://www.screencast.com/t/whnDCn4dA) |
| 2.4 | Test Email Services | [3 min](https://www.screencast.com/t/lHlV6BqQ) |
| 2.5 | Register An SSH Connection | [6 min](https://www.screencast.com/t/NPROCrXqu7) |
| 2.6 | Install ArcShell On A Remote Node Over SSH| [6 min](https://www.screencast.com/t/NZlbs28tJ) |
| 2.7 | Sync Changes To A Remote Node Over SSH | [4 min](https://www.screencast.com/t/CFD6lxQ2p4t) |
| 2.8 | Start And Stop ArcShell Services |[4 min](https://www.screencast.com/t/QhxhrKyMSc) |
| 2.9 | The ArcShell Menu | [4 min](https://www.screencast.com/t/VrW7Tvh9PfX) |

**Also Watch**

Install, Update, And Deploy From GitHub [10 min](https://www.screencast.com/t/clsSBkpp6Tt)

### SSH Connection Management With ArcShell

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Using ArcShell SSH Commands

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Scheduling Tasks With ArcShell

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Configuring ArcShell Keywords

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Adding Logging To Scripts

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Adding Debug To Scripts

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |s

### Adding Counters To Scripts

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Using ArcShell Sensors

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Sending Messages

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Writing Alerts

| # | Item| Description | Length |
| --- | --- | --- | --- |

| 0.0 | - | - | 0 min |

### Building Menus

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Collecting Statistics

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Creating Charts

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Packaging And Distribution Strategies

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Monitoring Log Files

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### Watching Files And Directories

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | - | - | 0 min |

### How To...

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | How To Move The Delivered (Installed) Home | - | 0 min |
| 0.0 | How To Move The User Home | - | 0 min |

### Developing Scripts and Modules With ArcShell

| # | Item| Description | Length |
| --- | --- | --- | --- |
| 0.0 | Special Functions | - | 0 min |
| 0.0 | "Clean Code" Overview | - | 0 min |
| 0.0 | Instrumenting Code | - | 0 min |
| 0.0 | Writing And Running Unit Tests | - | 0 min |
