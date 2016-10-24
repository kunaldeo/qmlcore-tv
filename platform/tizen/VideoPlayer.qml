Item {
	signal finished;
	signal error;
	property string	source;
	property Color	backgroundColor: "#000";
	property float	volume: 1.0;
	property bool	loop: false;
	property bool	flash: true;
	property bool	ready: false;
	property bool	muted: false;
	property bool	paused: false;
	property bool	waiting: false;
	property bool	seeking: false;
	property bool	autoPlay: false;
	property bool	networkConnected: true;
	property int	duration;
	property int	progress;
	property int	buffered;

	play: {
		var webapis = this._webapis
		log("Current state: " + webapis.avplay.getState());
		log('Play Video', this.source);
		try {
			webapis.avplay.play();
			log("Current state: " + webapis.avplay.getState());
		} catch (e) {
			log("Current state: " + webapis.avplay.getState());
			log(e);
		}
	}

	onRecursiveVisibleChanged: {
		var webapis = this._webapis
		if (value) {
			webapis.avplay.restore()
			if (webapis.avplay.getState() == "PLAYING")
			this.closeVideo()
			this.playImpl()
		} else {
			webapis.avplay.suspend()
		}
	}

	closeVideo: {
		var webapis = this._webapis
		log("Current state: " + webapis.avplay.getState());
		log('Close Video');
		try {
			webapis.avplay.close();
			log("Current state: " + webapis.avplay.getState());
		} catch (e) {
			log("Current state: " + webapis.avplay.getState());
			log(e);
		}
	}

	pause: {
		var webapis = this._webapis
		log("Current state: " + webapis.avplay.getState());
		log('Pause Video');
		try {
			webapis.avplay.pause();
			log("Current state: " + webapis.avplay.getState());
		} catch (e) {
			log("Current state: " + webapis.avplay.getState());
			log(e);
		}
	}

	stop: {
		var webapis = this._webapis
		log("Current state: " + webapis.avplay.getState());
		log('Stop Video');
		try {
			webapis.avplay.stop();
			log("Current state: " + webapis.avplay.getState());
		} catch (e) {
			log("Current state: " + webapis.avplay.getState());
			log(e);
		}
	}

	seekTo(val): {
		var webapis = this._webapis
		webapis.avplay.seekTo(val)
	}

	updateDuration: {
		//duration is given in millisecond
		var webapis = this._webapis
		var duration = webapis.avplay.getDuration();
	}

	updateCurrentTime: {
		//current time is given in millisecond
		var webapis = this._webapis
		var currentTime = webapis.avplay.getCurrentTime();
	}

	onAutoPlayChanged: {
		if (value)
			this.play()
	}

	onXChanged: { this.updateRect() }
	onYChanged: { this.updateRect() }
	onWidthChanged: { this.updateRect() }
	onHeightChanged: { this.updateRect() }

	onSourceChanged: {
		log("src", value)
		var webapis = this._webapis
		if (webapis.avplay.getState() == "PLAYING")
			this.closeVideo()
		this.playImpl()
	}

	updateRect: {
		var webapis = this._webapis
		webapis.avplay.setDisplayRect(this.x, this.y, this.width, this.height);
	}

	constructor: {
		var player = this._context.createElement('object')
		player.dom.setAttribute("id", "av-player")
		player.dom.setAttribute("type", "application/avplayer")
		if (!window.webapis) {
			log('"webapis" is undefined, maybe <script src="$WEBAPIS/webapis/webapis.js"></script> is missed.')
			return
		}
		this._webapis = window.webapis
		log("WEBAPIS", this._webapis)

		this.element.remove()
		this.element = player
		this.parent.element.append(this.element)
	}

	playImpl: {
		log("playImpl")
		var webapis = this._webapis
		log("playImpl open")
		webapis.avplay.open(this.source);
		log("playImpl setListener")
		webapis.avplay.setListener(this._listener);
		log("playImpl prepare")
		webapis.avplay.prepare();
		log("Init player, src:", this.source, "width:", this.width, "height:", this.height)
		webapis.avplay.setDisplayRect(this.x, this.y, this.width, this.height);
		log("Current state: " + webapis.avplay.getState());
		log("prepare complete");
		this.updateDuration()

		if (this.autoPlay)
			this.play()
	}

	onCompleted: {
		var self = this
		this._listener = {
			onbufferingstart : function() {
				log("Buffering start.");
				//showLoading();
			},
			onbufferingprogress : function(percent) {
				log("Buffering progress data : " + percent);
				//updateLoading(percent);
			},
			onbufferingcomplete : function() {
				log("Buffering complete.");
				//hideLoading();
			},
			oncurrentplaytime : function(currentTime) {
				log("Current Playtime : " + currentTime);
				self.updateCurrentTime(currentTime);
			},
			onevent : function(eventType, eventData) {
				log("event type: " + eventType + ", data: " + eventData);
			},
			onerror : function(eventType) {
				log("error type: " + eventType);
				self.error(eventType)
			},
			onsubtitlechange : function(duration, text, data3, data4) {
				log("Subtitle Changed.");
			},
			ondrmevent : function(drmEvent, drmData) {
				log("DRM callback: " + drmEvent + ", data: " + drmData);
			},
			onstreamcompleted : function() {
				log("Stream Completed");
			}
		};
		this.playImpl()

		this._webapis.network.addNetworkStateChangeListener(function(data) {
			if (data == 4) {		// Network is connected again.
				self.networkConnected = true
			} else if (data == 5) {	// Network is disconnected.
				self.networkConnected = false
			}
		})
	}
}
