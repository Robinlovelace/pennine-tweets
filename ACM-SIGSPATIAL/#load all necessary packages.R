#load all necessary packages
library(Rcpp)				
library(ggplot2)
library(ggmap)
library(maps)
library(mapproj)
library(rgeos)
library(maptools)
library(rgdal)

#copy dataset
tweets <- geoT 

#use grep to search the TweetText field for terms that are relevant to hiking the Pennine Way. Used \\b to find word matches.
#the relevant terms were: pennineway, pennine, pennines, hike, hiking, path, rambling, moor, moors, kinder scout, 
#stoodley pike, top withins, malham cove, pen y ghent, tan hill, high force, cauldron, high cup nick, cross fell, cheviot
tweets_pennineway <- tweets[grep('\\bpennineway\\b', tweets$TweetText, ignore.case=T),] 	#39
tweets_pennine <- tweets[grep('\\bpennine\\b', tweets$TweetText, ignore.case=T),] 			#38
tweets_pennines <- tweets[grep('\\bpennines\\b', tweets$TweetText, ignore.case=T),]			#16
tweets_hike <- tweets[grep('\\bhike', tweets$TweetText, ignore.case=T),]					#10			
tweets_hiking <- tweets[grep('\\bhiking\\b', tweets$TweetText, ignore.case=T),]				#10
tweets_footpath <- tweets[grep('\\bfootpath\\b', tweets$TweetText, ignore.case=T),]			#2 - but don't use
tweets_path <- tweets[grep('\\bpath\\b', tweets$TweetText, ignore.case=T),]					#10 - 
tweets_rambling <- tweets[grep('\\brambling\\b', tweets$TweetText, ignore.case=T),]			#1 - not good do not use
tweets_moor <- tweets[grep('\\bmoor\\b', tweets$TweetText, ignore.case=T),]					#45 - soome good, some traffic alerts
tweets_moors <- tweets[grep('\\bmoors\\b', tweets$TweetText, ignore.case=T),]					#45 - soome good, some traffic alerts			
tweets_kinder <- tweets[grep('\\bkinder scout\\b', tweets$TweetText, ignore.case=T),]		#4 - good
tweets_stoodley <- tweets[grep('\\bstoodley pike\\b', tweets$TweetText, ignore.case=T),]	#10 - good
tweets_topw <- tweets[grep('\\btop withins\\b', tweets$TweetText, ignore.case=T),]			#0
tweets_malham <- tweets[grep('\\bmalham cove\\b', tweets$TweetText, ignore.case=T),]		#26 - good
tweets_peny <- tweets[grep('\\bpen y ghent\\b', tweets$TweetText, ignore.case=T),]			#4 - good
tweets_tanhill <- tweets[grep('\\btan hill\\b', tweets$TweetText, ignore.case=T),]			#10 - good
tweets_highforce <- tweets[grep('\\bhigh force\\b', tweets$TweetText, ignore.case=T),]		#2 - very good
tweets_cauldron <- tweets[grep('\\bcauldron', tweets$TweetText, ignore.case=T),]	#1 - but not rel
tweets_hinick <- tweets[grep('\\bhigh cup nick\\b', tweets$TweetText, ignore.case=T),]		#1 - already included in pennineway tweets
tweets_crossfell <- tweets[grep('\\bcross fell\\b', tweets$TweetText, ignore.case=T),]		#13 - 11 need removing
tweets_cheviot <- tweets[grep('\\bcheviot\\b', tweets$TweetText, ignore.case=T),]			#4

View(tweets_pennineway)
View(tweets_pennine)
View(tweets_pennines)
View(tweets_hike)
View(tweets_hiking)
View(tweets_path)
View(tweets_moor)
View(tweets_moors)
View(tweets_kinder)
View(tweets_stoodley)
View(tweets_topw)
View(tweets_malham)
View(tweets_peny)
View(tweets_tanhill)
View(tweets_highforce)
View(tweets_crossfell)
View(tweets_cheviot)


#load gtools package in order to use smartbind function
library(gtools)

#combine the data frames created above into a single data frame
pwtweets <- smartbind(tweets_pennineway, tweets_pennine, tweets_pennines, tweets_hike, tweets_hiking, tweets_path, tweets_moor, tweets_moors, tweets_kinder, tweets_stoodley, tweets_malham, tweets_peny, tweets_tanhill, tweets_highforce, tweets_crossfell, tweets_cheviot)

#search for dulplicated values in the data frame
duplicated(pwtweets$TweetText)

#identfy rows that are duplicates using the duplicated function then remove these row numbers
duplicated_tweets <- which(duplicated(pwtweets$TweetText))
pwtweets <- pwtweets[-c(duplicated_tweets), ]

#create a new data frame of the unique values which can be used as a comparison
#unique_tweets <- unique(pwtweets)

#also removed some irrelevant tweets relating to traffic using the same method
#pwtweets<- pwtweets[-c(duplicatedrow, duplicatedrow...), ]

#convert the pwtweets data frame into a spatial data frame read for spatial processing
coordinates(pwtweets)<-~Lon+Lat

#load the pennine way trail map which was downlaoded from the national trails website
trail <- readOGR("NationalTrailPennineWay.gpx", layer="routes")

#change the CRS of the trail to UTM 30N - instructions called for British National Grid (4326) but this resulted in oval buffer
trail <- spTransform(trail, CRS("+init=epsg:27700"))

#plot the trail map to test
plot(trail)

#create buffer around the trail
trailBuf <- gBuffer(trail, width=5000)

#plot the trail buffer to test
plot(trailBuf)

#now the buffer is drawn conver the CRS to British National Grid
trailBuf <- spTransform(trailBuf, CRS("+init=epsg:4326"))

#plot to test
plot(trailBuf)

#set the CRS of the pwtweet dataset to match that of the trail buffer. It doesn't currently have a projection so:
proj4string(pwtweets)<-CRS("+init=epsg:4326")

#If it already has a projection then use the following:
pwtweets<-spTransform(pwtweets, CRS("+init=epsg:4326"))

#intersect the pwtweets and the trail buffer (spatial join) to remove tweets outside 5km buffer
pwtweets5km <- pwtweets[trailBuf, ]

#plot the results
points(pwtweets5km, col="red", cex=0.6)

#currently the tweets dataset is a spatial data frame, need it to be a data frame for further manipulation. so make a copy
pwtweets5km_df <- as.data.frame(pwtweets5km)

#export the tweet spatial data frame as an ESRI shapefile for use in GIS sw
writeOGR(pwtweets5km, dsn="ESRI Shapefile", layer="pwtweets5km_20141125", driver="ESRI Shapefile")

#removed some irrelevant tweets using the following code selecting from the unique id column X.1
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="37721"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="14913"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="15006"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="31832"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="19914"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="24556"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="44215"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="44889"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="47617"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="49072"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="50877"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="58441"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="58519"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="59090"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="2179"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="38359"),] #removing direct replies which start @...
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="33115"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="11807"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="1942"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="47268"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="52458"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="25300"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="3629"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="58380"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="16041"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7150"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="1447"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="58940"),] #removing direct replies
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="36326"),] #irrelevent
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="15969"),] #this removed the one reference to rambling - won't include this from the start in future

#obtain the date of the first and last tweet, daily count, daily min, max, med, mean
#load necessary library
library(plyr)

#since the date is not stored as a date format the following converts it to a date field
pwtweets_df$DateCreated <- as.Date(pwtweets_df$DateCreated, format="%d/%m/%Y")

#create a new data frame to store daily frequency of tweets
dailytweets <- count(pwtweets5km_df$DateCreated)

#obtain some simple statistics on the frequency of tweets
min_daily_tweets <- min(dailytweets$freq) #1
max_daily_tweets <- max(dailytweets$freq) #18
mean_daily_tweets <- mean(dailytweets$freq) #3.8
median_daily_tweets <- median(dailytweets$freq) #3

install.packages("stringi")
library(stringi)
library(stringr)

##create new data frame to find the number of words in each tweet before any processing - this is simple and just detects whitespace
tweet_words <- str_count(pwtweets5km_df$TweetText, "\\W+")
View(tweet_words)

#some simple statistics about the number of words in the tweets
min(tweet_words) #5
max(tweet_words) #31
mean(tweet_words) #14.60952
median(tweet_words) #14

#copy the dataset for further manipulation
tweets1126 <- pwtweets5km_df

#further text analysis using lovelace's Leeds Carnival example
tweets1126$TweetText <- tolower(tweets1126$TweetText) #convert to lower case

#create a function to remove whitespace
trim_whitespace <- function (x) gsub("^\\s+|\\s+$", "", x)

#apply trim_whitespace function
tweets1126$TweetText <- trim_whitespace(tweets1126$TweetText) 

# remove whitespace
tweets1126$TweetText = str_replace_all(tweets1126$TweetText, pattern = "\\s+", " ")

#remove URLs
tweets1126$TweetText <- gsub("http.*\\S", "", tweets1126$TweetText)

#remove spurious character
tweets1126$TweetText <- gsub("â€¦", "", tweets1126$TweetText)		

#remove punctuation - before doing so I looked to the emoticons and emoji and replaced these with text equivalents
tweets1126$TweetText <- removePunctuation(tweets1126$TweetText)

	#alternative to remove puctuation but keep . period ? question mark and ! exclamation point
	punct <- '[]\\\"\'#$%&(){}+*/:;,_`|~\\[<=>@\\^-]'
	tweets1122$TweetText <- gsub(punct, "", tweets1126$TweetText )

#remove non-alphanumeric characters
tweets1126$TweetText <- str_replace_all(tweets1126$TweetText, "[^[:alnum:]]", " ")

#it may be necessary to rerun the remove whitespace and trim whitespace after removing the punctuation etc. I found some spurious whitespace	


						#BELOW IS A SUB-ROUTINE I CONDUCTED TO EXTRACT HASHTAGS BEFORE TEXT MANIPULATION
						#extract all the hashtags for construction of a word cloud showing the most used hashtags
						hashtags < tweets1126
						hashtag.regex <- perl("(?<=^|\\s)#\\S+")
						hashtags <- str_extract_all(tweets1126$TweetText, hashtag.regex)

						#create word cloud of the hashtags
						hashtags <- unlist(hashtags)
						head(hashtags1)
						unique_hashtags <- unique(hashtags1)
						hashtag_words <- table(hashtags1)
						count_hashtags <- NULL

						#small for loop to iterate through and count the hashtags
						for (i in 1:length(unique_hashtags)) {
						+     count_hashtags[i] = sum(hashtags1 == unique_hashtags[i])
						+     names(count_hashtags)[i] <- unique_hashtags[i]
						+ }

						sort(count_hashtags, decreasing =T)
						library(wordcloud)
						wordcloud(unique_hashtags, freq = count_hashtags, scale = c(5, 0.3), min.freq = 2) # this config fits page

#break the tweets down into individual words
wordlist <- str_split(tweets1126$TweetText, pattern = " ")
head(wordlist)

#words per tweet
words_per_tweet <- sapply(wordlist, length)
min(wordlist, length)

#plot words per tweet as a histogram
qplot(words_per_tweet, geom = "histogram")

# create a string of all the words in the entire dataset
all_words <- unlist(wordlist)

#find the unique words (remove duplicates)
unique_words <- unique(all_words)

#create a table of all words
count_words_alt <- table(all_words)

#set count words data to null
count_words <- NULL
						#small for loop to iterate through and count the unique words
						for (i in 1:length(unique_words)) {
						count_words[i] = sum(all_words == unique_words[i])
						names(count_words)[i] <- unique_words[i]
						}
#sort the words frequency decreasing
sort(count_words, decreasing = T )[1:20]

#view the data frame
head(count_words)

library(wordcloud)

#plot a wordcloud of the word frequencies
wordcloud(unique_words, freq = count_words, scale = c(50, 0.1), min.freq = 2)

pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="1214"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7730"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="3410"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="9998"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="8589"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="2677"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="4284"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="8135"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7449"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="6242"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="4275"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="4982"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="6539"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="4137"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="8071"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7050"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="8866"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="9300"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="3254"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7393"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="9934"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="3831"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="8318"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="8537"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="414"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="1784"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7325"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7563"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="684"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="4523"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="2122"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="8604"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="4831"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="5765"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="4207"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="8538"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="829"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="5980"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="2962"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="5718"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="235"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="718"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="627"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="6523"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7414"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="7824"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="9448"),]
pwtweets_df <- pwtweets_df[!(pwtweets_df$TweetID=="9865"),]

library(plyr)

#calculating the daily frequency of tweets and plotting them in a bar chart.
tweets <- geoT
tweets$DateCreated <- as.Date(tweets$DateCreated, format="%d/%m/%Y")
daily_tweets <- count(tweets$DateCreated)

daily_tweets_xaxis<-c("06/03","06/04","06/05","06/06","06/07","06/08","06/09","06/10","06/11","06/12", "06/16","06/17","06/18","06/19","06/20","06/21","06/22","06/23","06/24","06/25","06/26","06/27","06/28","06/29","06/30","07/01","07/02","07/03","07/04","07/05","07/06","07/07","07/08","07/10","07/11","07/12","07/13","07/14","07/15","07/16","07/17","07/18","07/19","07/20","07/21", "07/22", "07/23", "07/24", "07/25")

plot<-barplot(daily_tweets$freq,
               main = 'Daily Tweets',
               xlab= 'Day',
               ylab = 'Number of Tweets', ylim=c(0,2000),
               names.arg=daily_tweets_xaxis, las=2, 
			   col="#55acee", border="#66757f", cex.axes=0.75, cex.lab=0.75, cex.names=0.75)

min(daily_tweets$freq)
#404
max(daily_tweets$freq)
#1860
mean(daily_tweets$freq)
#1234
median(daily_tweets$freq)
#1221
sd(daily_tweets$freq)
#275.2934

#plotting the frequency of tweets in the processed 161 tweets
tweets0117$DateCreated <- as.Date(tweets0117$DateCreated, format="%d/%m/%Y")
dailytweets0117<- count(tweets0117$DateCreated)

processed_daily_xaxis<-c("06/03","06/04","06/05","06/06","06/07","06/08","06/10","06/11","06/16","06/18","06/19","06/20","06/21","06/22","06/23","06/24","06/25","06/26","06/27","06/28","06/29","06/30","07/01","07/02","07/03","07/04","07/05","07/06","07/07","07/10","07/11","07/12","07/13","07/14","07/15","07/16","07/17","07/19","07/20","07/21", "07/22", "07/24")

plot<-barplot(dailytweets0117$freq,
                                      main = 'Daily Tweets',
                                      xlab= 'Day',
                                      ylab = 'Number of Tweets', ylim=c(0,20),
                                      names.arg=processed_daily_xaxis, las=2, 
                                      col="#55acee", border="#66757f", cex.axes=0.75, cex.lab=0.75, cex.names=0.75)

min(dailytweets0117$freq)
#1
max(dailytweets0117$freq)
#18
mean(dailytweets0117$freq)
#3.833333
median(dailytweets0117$freq)
#3
sd(dailytweets0117$freq)
#3.230319

#plotting the number of followers against the number of following
plot(tweets$n_following, tweets$n_followers, main = "Plot of numbers of followers against number of following", xlab= "number of following", ylab="number of followers", col="#55acee", cex=0.5)

#plotting the word frequency and the number of words and a wordcloud

install.packages("stringi")
library(stringi)
library(stringr)

##create new data frame to find the number of words in each tweet before any processing - this is simple and just detects whitespace
tweet_words0117 <- str_count(tweets$TweetText, "\\W+")

#some simple statistics about the number of words in the tweets
min(tweet_words0117) #5
max(tweet_words0117) #31
mean(tweet_words0117) #14.60952
median(tweet_words0117) #14

#to plot the word frequency first need to order the no of words ascending - before this
#need to convert the atomic vector into a data frame
tweet_words0117<-data.frame(tweet_words0117)
tweet_words0117 <- tweet_words0117[order(tweet_words0117),]

tweet_words0117 <- as.data.frame(tweet_words0117)
ggplot(tweet_words0117, aes(x=tweet_words0117)) + geom_histogram(binwidth=1, colour="#66757f", fill="#55acee") + geom_vline(aes(xintercept=mean(tweet_words0117, na.rm=T)), colour="red", linetype="dashed", size=1) + xlab("number of words") +
+     ylab("frequency") +
+     ggtitle("Histogram: number of words in each tweet")

# A ROUTINE I TO EXTRACT HASHTAGS
						#extract all the hashtags for construction of a word cloud showing the most used hashtags
						hashtags <- tweets
						hashtags$TweetText <- tolower(hashtags$TweetText)
						hashtag.regex <- perl("(?<=^|\\s)#\\S+")
						hashtags <- str_extract_all(hashtags$TweetText, hashtag.regex)

						#the below instance of hashtags provides a list of every hashtag in the dataset - 15,090 in totoal
						hashtags <- unlist(hashtags)
						
#create word cloud of the hashtags
						head(hashtags)

						#unique_hashtags provides all the unique hastags from the dataset - 7,866 unique hashtags used in dataset
						unique_hashtags <- unique(hashtags)
						
						hashtag_words <- table(hashtags)
						count_hashtags <- NULL

						#small for loop to iterate through and count the hashtags
						for (i in 1:length(unique_hashtags)) {
						+     count_hashtags[i] = (sum(hashtags == unique_hashtags[i]))}
						names(count_hashtags)[i] <- unique_hashtags[i]

						sort(count_hashtags, decreasing =T)
						library(wordcloud)
						wordcloud(unique_hashtags, freq = count_hashtags, scale = c(5, 0.3), min.freq = 2) # this config fits page