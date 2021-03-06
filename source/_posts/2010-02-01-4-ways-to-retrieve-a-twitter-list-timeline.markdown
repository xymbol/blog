---
layout: post
title: 4 Ways to Retrieve a Twitter List Timeline
hero_image: /blog/images/heros/post-high.jpg
comments: true
author:
  name: Santiago Pastorino
  email: santiago@wyeworks.com
  twitter_handle: spastorino
  github_handle:  spastorino
  image:  /images/team/santiago-pastorino.jpg
  description: WyeWorks Co-Founder, Ruby on Rails Core Team Member
published: true
---
For past few days we had been working on the new version of the WyeWorks site, so stay tunned.
This new version will have a twitter section, where the last 5 tweets of our team will be displayed.

<!--more-->

So first thing I had to do was installing the twitter gem:
{% codeblock %}gem install twitter{% endcodeblock %}

In order to achieve this, I've found 3 different ways using the twitter gem, plus one not yet implemented on the gem, that I've already proposed the patch.
The dumbest one would be:

{% codeblock lang:ruby %}#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'

users = %w(wyeworks spastorino joseicosta smartinez87 nartub)

tweets = users.map { |user_name| Twitter::Search.new.from(user_name) }.
               inject([]) { |tweets, search| tweets + search.fetch(5).results }.
               sort { |t1, t2| Date.parse(t2.created_at) <=> Date.parse(t1.created_at) }[0,5]

tweets.each do |tweet|
  puts tweet.created_at
  puts tweet.from_user
  puts tweet.profile_image_url
  puts tweet.text
end{% endcodeblock %}

What this does is retrieve the last 5 tweets of each user and merge them sorted by date.
Obviously, best thing to do would be directly retrieving the last 5 tweets from the @wyeworks/team list.
Only way to do this using the gem requires authentication, despite the list being public.
In order to authenticate, we may take two paths, the first one would be using HTTP Authentication:

{% codeblock lang:ruby %}#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'

httpauth = Twitter::HTTPAuth.new('wyeworks', 'password')
base = Twitter::Base.new(httpauth)
base.list_timeline('wyeworks', 'team', :page => 1, :per_page => 5).each do |tweet|
  puts tweet.created_at
  puts tweet.user.screen_name
  puts tweet.user.profile_image_url
  puts tweet.text
end{% endcodeblock %}

The other and preferred way for authentication is OAuth, since we don't have to send the user and password through the network.
In order to make OAuth work with twitter, we have to create an application at [https://apps.twitter.com/](https://apps.twitter.com/)
Once we've created the app, twitter provides us with a Consumer Key and a Consumer Secret, needed to authenticate using OAuth

{% codeblock lang:ruby %}#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'

oauth = Twitter::OAuth.new('consumer token', 'consumer secret')

begin
  oauth.authorize_from_access(oauth.request_token.token, oauth.request_token.secret)

  base = Twitter::Base.new(oauth)
  base.list_timeline('wyeworks', 'team', :page => 1, :per_page => 5).each do |tweet|
    puts tweet.created_at
    puts tweet.user.screen_name
    puts tweet.user.profile_image_url
    puts tweet.text
 end
rescue OAuth::Unauthorized
  puts "> FAIL!"
end{% endcodeblock %}

Either of these ways works just fine, but no one completely satisfied me, since we are working with a **public** list, so as far as I can see authentication is out the question, even more when anyone can see it directly from the web without authenticating.
For this reason, I started looking at the Twitter API searching for a non-authentication way to do it: Here's what I found ...
You can test that making a request to [http://api.twitter.com/1/wyeworks/lists/team/statuses.json?page=1&per_page=5](http://api.twitter.com/1/wyeworks/lists/team/statuses.json?page=1&per_page=5), obtaining the list as a json, or xml in case you change the .json to .xml

So I've came up with this monkey-patch:

{% codeblock lang:ruby %}module Twitter
  # :per_page = max number of statues to get at once
  # :page = which page of tweets you wish to get
  def self.list_timeline(list_owner_username, slug, query = {})
    response = HTTParty.get("http://api.twitter.com/1/#{list_owner_username}/lists/#{slug}/statuses.json", :query => query, :format => :json)
    response.map{|tweet| Hashie::Mash.new tweet}
  end
end{% endcodeblock %}

Being able to get the list without authenticating by:

{% codeblock lang:ruby %}Twitter.list_timeline('wyeworks', 'team', :page => 1, :per_page => 5).each do |tweet|
   puts tweet.created_at
   puts tweet.user.screen_name
   puts tweet.user.profile_image_url
   puts tweet.text
end{% endcodeblock %}

I've already contacted the gem's authors, proposing this patch: [http://github.com/spastorino/twitter/commit/aed3a298b613a508bb9caf93afc7f12c50626ad7](http://github.com/spastorino/twitter/commit/aed3a298b613a508bb9caf93afc7f12c50626ad7). Wynn Netherland already told me it's pretty probable that it will be approved.

Until then, you can make use of this functionality from my fork [http://github.com/spastorino/twitter](http://github.com/spastorino/twitter)

**UPDATE #1:** My fork was merged into [http://github.com/jnunemaker/twitter](http://github.com/jnunemaker/twitter) master branch and twitter 0.8.3 was published through [Rubygems](http://rubygems.org/gems/twitter)
