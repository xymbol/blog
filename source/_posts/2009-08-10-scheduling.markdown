---
layout: post
title: Scheduling in Ruby
hero_image: /blog/images/heros/post-high.jpg
comments: true
author:
  name: Sebastián Martínez
  email: sebastian@wyeworks.com
  twitter_handle: smartinez87
  github_handle:  smartinez87
  image:  /images/team/sebastian-martinez.jpg
  description: VP of Engineering at WyeWorks. Ruby on Rails hacker. ExceptionNotification maintainer. Coffee & bacon lover.
published: true
---
Scheduling tasks is something we all need to know to do, for it's quite common in applications. Fetching feeds, indexing some data, processing files at a periodical time, that happens a lot.
You are probably quite familiar then with the linux cron, if you had to deal with scheduling stuff in the past, but there is something you may not. Let me introduce you the [*Whenever*(Whenever)](http://github.com/javan/whenever) gem. 
What is it? A simple gem to schedule tasks writing them in nice ruby syntax...just let the gem work it's magic and deal with the cron.

<!--more-->

In order to install it, you have to add first the github source, only if you never done it :
{% codeblock %}$ gem sources -a http://gems.github.com
$ sudo gem install javan-whenever
{% endcodeblock %}

To get started, just place yourself in the app path and type
{% codeblock %}$ wheneverize . {% endcodeblock %}
This will create an initial config/schedule.rb for you.

There you can nicely write tasks to run.

Some examples are: 
{% codeblock lang:ruby %}every 3.hours do
    runner "MyModel.some_process"
    rake "my:rake:task"
    command "/usr/bin/my_great_command"
  end

  every 1.day, :at => '4:30 am' do
    runner "MyModel.task_to_run_at_four_thirty_in_the_morning"
  end

  every :hour do # Many shortcuts available: :hour, :day, :month, :year, :reboot
    runner "SomeModel.ladeeda"
  end

  every :sunday, :at => '12pm' do # Use any day of the week or :weekend, :weekday
    runner "Task.do_something_great"
  end
{% endcodeblock %}

Another nice thing to do is integrate it with Capistrano.
{% codeblock lang:ruby %}
 after "deploy:symlink", "deploy:update_crontab"

  namespace :deploy do
    desc "Update the crontab file"
    task :update_crontab, :roles => :db do
      run "cd #{release_path} && whenever --update-crontab #{application}"
    end
  end
{% endcodeblock %}

The official documentation provides this way to integrate it, but we found some little details, and the solution is here for you.

If you integrate it by the regular way, when making multiple deploys, it will configure several tasks to run in your cron file. Why? Because the path of the current application changed, and the gem uses the path (by adding a comment line) when updating the cron.
What should we do then? Simple,  change the **run** line with this:
{% codeblock lang:ruby %}run "cd #{current_path}; whenever -i #{current_path}/config/schedule.rb"
{% endcodeblock %}

What have we done? We used the -i option, which makes an update, but passing the comment we want, and make it not to change in every deploy.

Feel free to try it and leave your comments !!
