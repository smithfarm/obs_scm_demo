# obs_scm_demo

## What is this?

This is "learn by doing." Specifically, we will learn about `obs_scm` by
bootstrapping a software project in github and setting up automated builds in
the OBS, while maintaining both the spec file and the changes file in git, all
in the simplest possible way.

## What is github? What is the OBS? What is obs_scm?

[Github](https://github.com) is a source code forge.

OBS stands for the [Open Build Service](https://openbuildservice.org).

SCM is an acronym which means Source Code Management.

`obs_scm` is an OBS Source Service for automating the process of
grabbing source code from a Source Code Management service, such as github, for
the purpose of building it and packaging it.

## But the script in this repo is trivial. It won't do all that stuff.

This (`obs_scm_demo`) is not an application or software project in the
traditional sense. There is no program here that will "do" something for you.
You have to do the work yourself, but this README.md will tell you "how to" do
it.

The idea here is that the reader of `README.md` will try to do what is described
and, along the way, obtain hands-on experience with `obs_scm`.

If you do that, you will be bootstrapping a completely new software project for
future development, not running software that has already been developed.

## But I already know how to bootstrap a new software project!

When I set out to write this `README.md`, I realized that, while I did know in
general how to bootstrap a new software project, there were some pain points I
did not know how to avoid. First, I didn't know how to set up my project so that
builds in OBS would be triggered automatically whenever I push code to github.
For that to be successful, OBS would need to grab the spec file and the changes
file from the git repo as well, and it wasn't clear to me how to arrange that.
Finally, OBS needs to be able to automatically determine the current version
number from the state of the git repo. In all my previous projects, I was doing
some or all of these things manually using `osc` commands, and there didn't seem
to be any way to fully automate these steps.

(Please note: this is not about fully automating the process of editing the
changes file. It has never been my intention to "automate away" this file or
somehow rid myself of my responsibility, as the maintainer of a package that is
carried in openSUSE, to add appropriate entries to the changes file whenever
I change the package. What I *did* want to achieve, though, was to maintain the
changes file in git, and fully automate the process of updating the file in
OBS.)

Learning how to do all of the above required effort and I wrote this `README.md`
in the hopes of making the learning process smoother for others.

## OK, I'm ready. Let's get started.

OK. Here we go.

## Review the documentation

Before getting our hands dirty, let's review the OBS Source Services
documentation. I recommend to study the whole chapter with care.

[Using Source Services chapter of OBS User Guide](https://openbuildservice.org/help/manuals/obs-user-guide/cha.obs.source_service.html)

## Global search and replace

If you are not "smithfarm" and you want to call your software project something
other than "obs_scm_demo", now would be a good time to globally search for these
two terms in this document and replace them with terms that make sense for you!

For example, if your github username is "foocity" and your OBS username is also
"foocity", and you want to call your software package "bar_blaz", you would do:

    sed -i -e 's/smithfarm/foocity/g' README.md
    sed -i -e 's/obs_scm_demo/bar_blaz/g' README.md

If your github username and your OBS username are different, I'm afraid you'll
have to replace "smithfarm" with the appropriate string manually.

## Create an empty git repo

Using the github web GUI, create an empty github repo.

[URL of your empty github repo](https://github.com/smithfarm/obs_scm_demo)

## Create a corresponding empty OBS package

Using the osc command-line client, create an empty OBS package

    oosc mkpac home:smithfarm/obs_scm_demo
    cd home:smithfarm/obs_scm_demo
    oosc ci -m"empty package"

Observe that a new empty package does get created on the server

    firefox https://build.opensuse.org/home:smithfarm/obs_scm_demo

Still in the local directory home:smithfarm/obs_scm_demo, note that the
directory is empty. In other words, we are starting from an empty package: we
are bootstrapping.

## Add the github repo to the OBS package (locally)

Add the github repo

    oosc add https://github.com/smithfarm/obs_scm_demo.git

Observe that a `_service` file has been created

    oosc status
    ls
    cat _service

While we will need a `_service` file, this auto-generated one is not appropriate.
For example, it generates a tar archive from the git repo. Traditionally, RPMs
have been built from tarballs, but in our case there is no need for this step
so we will eliminate it using a spec file trick that will be explained later,
when we introduce the spec file.

## What is the `_service` file?

The `_service` file is a blob of XML which will be processed by the OBS to obtain
the source code of our package from github and tweak it so it can be built and
packaged into an RPM.

In our case, since we will be maintaining the spec file and the changes file in
the git repo, the `_service` file is the only file we will need to maintain in OBS.

The tedium of having to use two source code repositories (github, OBS) will be
thereby minimized, and we will gain the advantages of OBS while minimizing our
interaction with it, since we will empower github itself to trigger our OBS
builds, and OBS will get everything it needs (except for the `_service` file
itself) from the git repo.

## Populate the `_service` file

Replace the auto-generated contents of the `_service` file with the following:

    <services>
      <service name="obs_scm">
        <param name="url">https://github.com/smithfarm/obs_scm_demo.git</param>
        <param name="scm">git</param>
        <param name="revision">main</param>
        <param name="extract">obs_scm_demo.spec</param>
        <param name="extract">obs_scm_demo.changes</param>
      </service>
      <service mode="buildtime" name="set_version"/>
    </services>

## Create an initial changes file

Go over to the local clone of the "obs_scm_demo" github repo, and add a 
changes file (the "osc vc" command can be used anywhere)

    touch obs_scm_demo.changes
    osc vc

This will open an editor. Make the changes file look like this:

    -------------------------------------------------------------------
    Wed Feb  1 09:59:28 UTC 2023 - Nathan Cutler <ncutler@suse.com>

    - Bootstrap

Add, commit

    git add obs_scm_demo.changes
    git commit -m"changes file"

## Create an initial spec file

Next, still in the git clone directory, create a file called
"obs_scm_demo.spec" with the following contents

    Name:           obs_scm_demo
    Summary:        A demo of OBS_SCM
    Version:        0
    Release:        0
    License:        BSD-3-Clause
    Group:          Documentation/Howto
    URL:            https://github.com/smithfarm/obs_scm_demo
    Source0:        _service
    BuildArch:      noarch

    %description
    All you ever wanted to know about OBS_SCM, but were afraid to ask.

    %prep
    %setup -q -n %_sourcedir/%name-%version -T -D

    %build

    %install
    install -D -m 0755 obs_scm_demo %{buildroot}%{_bindir}/obs_scm_demo

    %files
    %license LICENSE
    %{_bindir}/obs_scm_demo

    %changelog

This spec file is interesting because there is no tarball. I can't explain
exactly how it works, but I do know that the "magic" is in the line

    %setup -q -n %_sourcedir/%name-%version -T -D

In a classic RPM build, the %setup macro expects to find a source code tarball
which it unpacks so the build can take place. In our case, the `obs_scm` source
service clones a git repo containing the source code, and there is no tarball.
The "-D" option disables deleting of the source code directory and the "-T"
option disables unpacking of the source code tarball.

For more information, see [the RPM Packaging
Guide](https://rpm-packaging-guide.github.io/#setup) and [How to integrate
external SCM
sources](https://openbuildservice.org/help/manuals/obs-user-guide/cha.obs.best-practices.scm_integration.html)

Add, commit

    git add obs_scm_demo.spec
    git commit -m"spec file"

## Create a simple shell script

Our software project needs some source code. Create a file called
"obs_scm_demo" with the following contents:

    #!/bin/sh
    echo "Hello, obs_scm!"

Add, commit

    chmod 755 obs_scm_demo
    git add obs_scm_demo
    git commit -m"The obs_scm_demo executable"

## Push the new commits to the remote

Push to the remote (github.com/smithfarm/obs_scm_demo)

    git push

## Note that "main" is our new overlord

Github no longer uses "master" as the default branch name, because the word
"master" has been associated with slavery. But the obs_scm source service still
defaults to "master" and might fail if this branch doesn't exist. Therefore,
it's a good idea to explicitly set the branch that obs_scm will use. In the
`_service` file, this is done by the line

    <param name="revision">main</param>

## Step back, relax

At this point, let us step back, relax a little, and review what we have done.
Maybe we can clarify a few things.

In the github repo, we should have the following files:

    LICENSE  obs_scm_demo  obs_scm_demo.changes  obs_scm_demo.spe

In the OBS checkout, we should have just one file:

    _service

The "beauty", and indeed the purpose, of this exercise is to demonstrate not
only how to maintain the source code of your project in git, and how to
automate the process of getting that source code into the OBS, but also to
demonstrate that it's possible to maintain the spec file and the changes file
in git, too.

Why have all your project's files in the git repo, *except* for the spec file
and the changes file? Are these two files really OBS-specific? Aren't they part
of the source code just like everything else?

## Review server-side and local build concepts

The OBS gives us two ways of building our package: server-side build and local
build. Being able to build locally is useful since the server-side builds
sometimes take longer and using server-side builds during debugging can be
tedious.

That being said, our goal here is to not have to deal with package building
manually at all: package building should happen auto-magically whenever we
push something to the main branch in github.

## What about PRs?

With OBS workflows, Github actions, and possibly other (relatively complicated)
stuff, it might be possible to build CI pipelines, automatically trigger builds
of WIP branches, show the build results in github's PR interface, etc. We won't
be doing any of that here.

What we will be doing is to set up our project so that every push to the main
branch in github causes a webhook to fire, and this webhook will trigger a new
build in OBS.

## Why do we need OBS source services?

Simply because the part of OBS that is able to clone github repo and act on its
contents is implemented as an OBS source service.

When we trigger a build, either locally or on the server, the first thing that
happens is it "runs" the `_service` file. This is necessary because running the
`_service` file clones the github repo with our package's source code in it.
Crucially, it also extracts the spec file, and without a spec file no build can
take place.

## Which OBS source services will we be using?

By "running" the `_service` file, we mean: running the individual source services
as configured, and in the order in which they appear, in that file. We've already
looked at this file once before, but it's worth looking at it again:

<services>
  <service name="obs_scm">
    <param name="url">https://github.com/smithfarm/obs_scm_demo.git</param>
    <param name="scm">git</param>
    <param name="revision">main</param>
    <param name="extract">obs_scm_demo.spec</param>
    <param name="extract">obs_scm_demo.changes</param>
  </service>
  <service mode="buildtime" name="set_version"/>
</services>

The first service mentioned is `obs_scm`. This source service is packaged as
obs-service-obs_scm and since we will need it for local builds, let us install
that on our local system now:

    zypper ref
    zypper install obs-service-obs_scm

The second service is "set_version". Note that it has mode="buildtime" which
means it only runs at build time. Let's install it, too, because if we don't
install it our local build will fail when it tries to run this service.

    zypper install obs-service-set_version

At this point you might be tempted to trigger a local build with "oosc build".
That won't work, though, because there is no spec file yet. But that's not a 
problem, because the spec file will be downloaded from the git repo when we run
the `obs_scm` service. Although it is true that running the `_service` file is
one of the first things that "oosc build" does, it currently refuses to run at
all if there is no spec file present.

## Run the obs_scm source service locally

Having established that we must run obs_scm explicitly in order to be able to
trigger a local build, let us do that now.

    oosc service run obs_scm
    ls

## Review the stuff obs_scm creates

When `obs_scm` finishes without an error, it creates a bunch of stuff!

    _service
    _service:obs_scm:obs_scm_demo-1675246327.57faa49.obscpio
    _service:obs_scm:obs_scm_demo.changes
    _service:obs_scm:obs_scm_demo.obsinfo
    _service:obs_scm:obs_scm_demo.spec
    obs_scm_demo

What is all of this? Well, it's the output produced by our run of the obs_scm
service. The directory `obs_scm_demo` is a local clone of our git repo. This is
packed up into a cpio archive. Before it is packed up, the changes file and
spec file are extracted (see the "extract" param lines in our `_service` file).
The last file, obsinfo, contains some obs_scm-specific metadata that we don't
necessarily need to know much about.

## Trigger a local build

Now that we have a spec file, we can trigger a local build:

    oosc build openSUSE_Leap_15.3

Does the local build succeed? Fingers crossed! 

## What now? My local package checkout has all this clutter in it now!

In our local package checkout, this clutter will need to be removed at some
point, because we don't want to commit any of it to the server. The only file
we are maintaining in the OBS is `_service`, so we need to take care not to try
to commit anything else.

    oosc status
    rm -rf _service:* obs_scm_demo
    oosc status

## Trigger a server-side build

Now, "oosc status" should show something like this:

    M    _service

When we commit this file to the server, a remote build should be triggered.

    oosc commit -m"_service: initial commit"
    firefox https://build.opensuse.org/package/show/home:smithfarm/obs_scm_demo

Watch https://build.opensuse.org/package/show/home:smithfarm/obs_scm_demo in
the browser. Click on the "Refresh" button periodically if necessary. Look
at the build log. Does the build succeed? Fingers crossed!

If the build succeeds, you'll notice that the same metadata files appear at
https://build.opensuse.org/package/show/home:smithfarm/obs_scm_demo as we
saw locally. The only one that doesn't appear is the local git clone - the
server cleans that one up automatically.

## So we're done?

No. We have set up and populated a git repo. We have also set up an OBS package
with a `_service` file so the OBS is able to fetch everything it needs from the
git repo. But we are still triggering builds manually. We want the builds to be
triggered automatically whenever we push to the git repo on github.

## What is needed for github to trigger our OBS builds?

The github feature we will use for this is called "Webhook". A "webhook" is 
an event that we configure to fire on every push.

Obviously, github will need to authenticate itself to the OBS in order to
trigger the build. The OBS will not need to authenticate itself to
github in order to clone the repo, however, because the repo is public.
(If your github repo is not public, this simple method will presumably not work.)

So, on the github side, there will be a webhook which is basically a URL
(perhaps more fancifully, we could call it an "API endpoint") and the secret
token which will unlock this API endpoint for us. On the OBS side there is the
package, containing a `_service` file, and a service token that will run that
service file and build the resulting code for all of the configured build
targets.

## What is an authentication token?

A token authenticates just like a username/password pair, but it's just a
single string. The idea is that the privileges associated with a token can be
restricted, so if the token ever gets public, the damage that a malicious
person can cause with it will be limited. Also, the token can be revoked
easily, without needing to change the user's login credentials.

## Create a package-specific OBS service token

Create an OBS service token linked to our project/package:

    oosc token --create home:smithfarm obs_scm_demo

## Save the OBS service token in a safe place

This will return a small blob of XML. Save the above command and the XML it
returned in your password manager under, e.g., "SUSE/obs_scm".

The XML blob will look something like this:

    <status code="ok">
      <summary>Ok</summary>
      <data name="token">uvwxyz</data>
      <data name="id">12345</data>
    </status>

We will need both values, the token and its id number, in the next step.

## Create the github webhook

Go to github.com/smithfarm/obs_scm_demo -> Settings -> Webhooks.

Click on the "Add webhook" button. Fill in the form with:

    Payload URL: https://build.opensuse.org/trigger/webhook?id=12345

    Secret: uvwxyz

Replace 12345 with the OBS token numerical ID previously obtained. Replace
uvwxyz with the OBS token itself. Both of these values were obtained in the
previous step.

Leave all other values in the form at their defaults.

Review the webhook just created by browsing to

    https://github.com/smithfarm/obs_scm_demo/settings/hooks

## Review recent webhook deliveries

Now, github.com will send some blob of data to the URL shown in the webhook
whenever any of the defined events occurs on the repository. It also sent
a "ping" hook delivery when the webhook was created. This "ping" delivery
should have been successful. Let's verify that.

Make sure you are looking at the following URL in your browser

    https://github.com/smithfarm/obs_scm_demo/settings/hooks

You should see a list of webhooks defined on this repo. Probably there will be
only one - the one we just created. Click on "Edit". This will get you to the
same dialog you used a moment ago to create the webhook. This time, however,
there is a new tab: "Recent Deliveries". Click on this tab.

A table is displayed showing all the recent deliveries of this webhook. There
should be one entry in the table, and it should start with a green checkmark.
If you hover your mouse over that checkmark, it should say "Success". If you
click on the three dots at the end of the table row, you will see the Request
(headers and payload) github sent to OBS and the Response (headers and body)
it received back from OBS.

Assuming all is well, at this point we are done. To demonstrate that pushes
to the git repo trigger builds in OBS, we can push something.

## Push a code change to the git repo

In your local git clone, make some code change and commit it.

    vim obs_scm_demo
    git status
    git commit -m"obs_scm_demo: trivial change to a trivial script"
    git push

## See what happens

Two things should happen. First, you should see another row appear in the
webhook's "Recent Deliveries" table. Second, you should see a new revision
appear in the OBS package. The appearance of a new revision should trigger
a server-side build.

## Are we done yet?

At this point, you should have achieved the goal. You have a github repo
with software source code, a spec file, and a changes file. You also have
an OBS package with the same name as the git repo. In this OBS package you have
a `_service` file containing an `obs_scm` service "stanza". This `_service` file
is triggered by a Webhook that we have set up in the git repo. The Webhook calls
an OBS service token endpoint that we created by running `oosc token --create`.

## What next?

You might have noticed that the RPMs built by the OBS in our package look
like this:

    obs_scm_demo-1675339511.804eaa2-lp154.19.1.noarch.rpm

The string "1675339511.804eaa2" is the RPM version and "lp154.19.1" is the
release. The release is set by the OBS at build time and should not be tampered
with. The version is set by `obs_scm` and it defaults to `%ct.%h` where `%ct` is
"Commit time as a UNIX timestamp, e.g. 1384855776" and `%h` stands for
"Abbreviated hash" (in our case, this is the hash identifying the tip commit in
the main branch of our git repo at the time when this build was triggered).

## What good is a version that looks like 1675339511.804eaa2"? It seems meaningless!

This default version number format is actually not that bad. As long as you
simply add commits to the tip of the main branch, the commit time will be
guaranteed to be an ever-increasing integer. Having the commit hash inside
the version number is also useful, because you can link any given RPM to the
commit it was built from.

## But I want to implement a different version number format

OK, let's implement a different version number format. Refer to the source
code of obs-service-tar_scm:

[https://github.com/openSUSE/obs-service-tar_scm/blob/master/tar_scm.service.in](https://github.com/openSUSE/obs-service-tar_scm/blob/master/tar_scm.service.in)

This file describes all the `obs_scm` parameters. One of them is called
"versionformat". This describes how the version string is interpreted. As we've
seen before, the default is `%ct.%h`.

If you want an actual version number like "0.0.1", you have two options: can
either specify it directly in the `_service` file using the `version` parameter
(but then you have to edit the `_service` file whenever the version number
changes), or you can specify the version number as a git tag. The git tag way
is probably what you want, since that allows you to set the version number in
git.

## What might a real-life version numbering scheme look like?

Let's say we want to have version numbers like "0.0.1.3+g54cacf2" where the
first three components (0.0.1) come from a release version tag that will look
like "v0.0.1", the fourth component is the number of commits that have been
added to the branch since that tag, and the last component (g54cacf2) is the git
hash in the format we are used to seeing when we run `git describe` ("g" + the
abbreviated commit hash). This avoids having a UNIX timestamp in our version
number, but we still have the git hash in there, and we can implement a release
workflow and describe our releases in `obs_scm_demo.changes`. In other words,
the first three version number components will be set manually by adding a tag,
while the fourth and fifth components will be determined by `obs_scm` at build
time.

## How to implement this version numbering scheme in obs_scm_demo?

First, add the following two lines to the `osc_scm` service stanza of
`_service`:

    <param name="versionformat">@PARENT_TAG@+%ct.%h</param>
    <param name="versionrewrite-pattern">v(.*)</param>

Now, your `_service` file should look like this:

    <services>
      <service name="obs_scm">
        <param name="url">https://github.com/smithfarm/obs_scm_demo.git</param>
        <param name="scm">git</param>
        <param name="revision">main</param>
        <param name="extract">obs_scm_demo.spec</param>
        <param name="extract">obs_scm_demo.changes</param>
        <param name="versionformat">@PARENT_TAG@.@TAG_OFFSET@+g%h</param>
        <param name="versionrewrite-pattern">v(.*)</param>
      </service>
      <service mode="buildtime" name="set_version"/>

Second, add a tag and push it:

    git tag v0.0.1
    git push origin v0.0.1

It can be an annotated tag if you like.

Third, "cut a release" by adding a new entry to the changes file:

    oosc vc

The new entry should look something like this:

    -------------------------------------------------------------------
    Thu Feb  2 12:04:45 UTC 2023 - Nathan Cutler <ncutler@suse.com> - 0.0.1

    - Update to version 0.0.1:
      + first release

Notice that the version number is appended to the end of the first line.
This is not required, but if you omit it you will get an RPMLINT warning at the
end of your builds.

Commit and push:

    git commit -am"Release version 0.0.1"
    git push origin

Look at the "Recent Deliveries" tab in your github repo (Settings -> Webhooks
-> Edit -> Recent Deliveries). You should see a new delivery with a green
checkmark (OBS responded with status 200 OK).

In the OBS web interface, go to your package and wait for it to finish
building. The binary RPM produced should now look like this:

    obs_scm_demo-0.0.1+1675339511.804eaa2-lp154.19.1.noarch.rpm

The reason this works is: we pushed the tag first, and the commit second.
If we had pushed the commit first and then the tag, the version number would not
have changed. This is because, even though pushing a tag causes github to
deliver a webhook to the OBS, OBS only triggers a build when the source code
changes, and that is not the case when pushing only a tag.

## git push --atomic

In more recent versions of git, and provided the other side supports it (github
does support it), you can use --atomic to push the commits and the tag at the
same time, in a single, "atomic" operation.

Make some source change and commit it:

     vim obs_scm_demo
     git commit -am"obs_scm_demo: some really trivial source code change"
     oosc vc  # add a new changes file entry for a new version 0.0.2
     git tag v0.0.2
     git status

Now, push this new commit and its corresponding tag, atomically:

     git push --atomic origin main v0.0.2

## OK. I want to cut a release. What are the steps?

1. add commits to main branch locally
2. determine the existing version (e.g. 0.0.2)
3. determine the new version (e.g. 0.0.3, 0.1.0, etc.)
4. add changes file entry ("osc vc")
5. commit the change file ("git commit -a -s -m"bump to 0.0.3")
6. add version tag ("git tag v0.0.3")
7. atomic push ("git push --atomic origin main v0.0.3")

## How to automate the release steps?

Wow, seven finicky steps which I will need to repeat for every release, without
making any mistake. Tedious! Is there any way to automate that?

Yes, these steps can of course be automated. A bash script, `checkin.sh` is
included in this repo which might give you some ideas in that direction!
