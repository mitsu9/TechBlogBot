require "feedjira"
require "active_record"
require "twitter"
require "yaml"

CONFIG = YAML.load_file('config.yml')
FEED = YAML.load_file('feed.yml')

# configure DB
ActiveRecord::Base.establish_connection(CONFIG["db"]["production"])
class Entry < ActiveRecord::Base

end

# create Twitter Client
client = Twitter::REST::Client.new do |config|
    config.consumer_key  = CONFIG["twitter"]["consumer_key"]
    config.consumer_secret = CONFIG["twitter"]["consumer_secret"]
    config.access_token  = CONFIG["twitter"]["access_token"]
    config.access_token_secret = CONFIG["twitter"]["access_token_secret"]
end

# get feed => if new, save and post
for url in FEED["url"] do
    feed = Feedjira::Feed.fetch_and_parse url
     puts feed.title
    for entry in feed.entries do
        if Entry.exists?(title: entry.title, url: entry.url, published: entry.published)
            # do nothing
            puts "already save to DB"
        else
            # save to DB
            newentry = Entry.new
            newentry.title = entry.title
            newentry.url = entry.url
            newentry.published = entry.published
            newentry.save

            # tweet about new entry
            tweet = "[" + feed.title + "] " + newentry.title + " / " + newentry.url
            if tweet.length < 140
                puts tweet
                client.update(tweet)
            else
                puts "long tweet"
            end
        end
    end
end
