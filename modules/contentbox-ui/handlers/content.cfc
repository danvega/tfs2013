/**
********************************************************************************
ContentBox - A Modular Content Platform
Copyright 2012 by Luis Majano and Ortus Solutions, Corp
www.gocontentbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
Apache License, Version 2.0

Copyright Since [2012] [Luis Majano and Ortus Solutions,Corp]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
********************************************************************************
* Base Content Handler
*/
component{

	// DI
	property name="authorService"		inject="id:authorService@cb";
	property name="categoryService"		inject="id:categoryService@cb";
	property name="contentService"		inject="id:contentService@cb";
	property name="commentService"		inject="id:commentService@cb";
	property name="CBHelper"			inject="id:CBHelper@cb";
	property name="rssService"			inject="id:rssService@cb";
	property name="validator"			inject="id:Validator@cb";
	property name="layoutService"		inject="id:layoutService@cb";
	
	// Pre Handler Exceptions
	this.preHandler_except = "previewSite";
	
	// pre Handler
	function preHandler(event,rc,prc,action,eventArguments){
		// Maintenance Mode?
		if( prc.cbSettings.cb_site_maintenance ){
			event.overrideEvent("contentbox-ui:page.maintenance");
			return;
		}

		// Get all categories
		prc.categories = categoryService.list(sortOrder="category",asQuery=false);

		// Home page determination either blog or a page
		// Blog routes are in the blog namespace
		if( event.getCurrentRoute() eq "/" AND prc.cbSettings.cb_site_homepage neq "cbBlog" AND event.getCurrentRoutedNamespace() neq "blog"){
			event.overrideEvent("contentbox-ui:page.index");
			prc.pageOverride = prc.cbSettings.cb_site_homepage;
		}
	}
	
	/**
	* Preview the site
	*/
	function previewSite(event,rc,prc){
		// Param incoming data
		event.paramValue("l", "");
		event.paramValue("h", "");
		
		var author = getModel("securityService@cb").getAuthorSession();
		// valid Author?
		if( author.isLoaded() AND author.isLoggedIn() AND compareNoCase( hash(author.getAuthorID()), rc.h) EQ 0){
			
			// Place layout on scope
			prc.cbLayout = rc.l;
			// Place layout root location
			prc.cbLayoutRoot = prc.cbRoot & "/layouts/" & rc.l;
			// Home page determination either blog or a page
			if( prc.cbSettings.cb_site_homepage NEQ "cbBlog"){
				// Override event and incoming page.
				event.overrideEvent("contentbox-ui:page.index");
				prc.pageOverride = prc.cbSettings.cb_site_homepage;
				// run it
				var eArgs = {noCache=true};
				runEvent(event="contentbox-ui:page.index", eventArguments=eArgs);
				// Override the layout
				event.setLayout(name="#prc.cbLayout#/layouts/pages", module="contentbox");
			}
			else{
				// Override layout and event so we can display it
				event.setLayout("#rc.l#/layouts/blog")
					.overrideEvent("contentbox-ui:blog.index");
				// run it
				runEvent("contentbox-ui:blog.index");
			}
			
		}
		else{
			// 	Invalid Credentials
			setNextEvent(URL=CBHelper.linkBlog());
		}
	}
	
	/**
	* Go Into maintenance mode.
	*/
	function maintenance(event,rc,prc){
		// If no maintenance view exists, just output data
		if( !layoutService.themeMaintenanceViewExists() ){
			event.renderData(data=prc.cbSettings.cb_site_maintenance_message);
		}
		else{
			// output maintenance view
			event.setLayout(name="#prc.cbLayout#/layouts/#layoutService.getThemeMaintenanceLayout()#", module="contentbox")
				.setView(view="#prc.cbLayout#/views/maintenance", module="contentbox");
		}
		
	}

	/*
	* Error Control
	*/
	function onError(event,faultAction,exception,eventArguments){
		var rc 	= event.getCollection();
		var prc = event.getCollection(private=true);

		// store exceptions
		prc.faultAction = arguments.faultAction;
		prc.exception   = arguments.exception;

		// announce event
		announceInterception("cbui_onError",{faultAction=arguments.faultAction,exception=arguments.exception,eventArguments=arguments.eventArguments});

		// Set view to render
		event.setLayout(name="#prc.cbLayout#/layouts/pages", module="contentbox")
			.setView(view="#prc.cbLayout#/views/error", module="contentbox");
	}

	/************************************** PRIVATE *********************************************/

	/**
	* Content display around advice that provides caching for content display and multi-format capabilities
	*/
	private function wrapContentAdvice(event,rc,prc,eventArguments,action){
		// param incoming multi UI formats
		event.paramValue("format", "contentbox");
		// If UI export is disabled, default to contentbox
		if( !prc.cbSettings.cb_content_uiexport ){
			rc.format = "contentbox";
		}
		
		// Caching Enabled? Then test if data is in cache.
		var cacheEnabled = ( prc.cbSettings.cb_content_caching AND !structKeyExists(eventArguments, "noCache") AND !event.valueExists( "cbCache" ) );
		if( cacheEnabled ){
			// Get appropriate cache provider from settings
			var cache = cacheBox.getCache( prc.cbSettings.cb_content_cacheName );
			// Do we have an override page setup by the settings?
			cacheKey = ( !structKeyExists( prc, "pageOverride" ) ? "cb-content-wrapper-#left(event.getCurrentRoutedURL(),255)#.#rc.format#" : "cb-content-wrapper-#prc.pageOverride#/.#rc.format#");
			// get content data from cache
			var data = cache.get( cacheKey );
			// if NOT null and caching enabled and noCache event argument does not exist and no incoming cbCache URL arg, then cache
			if( !isNull( data ) ){
				// set cache headers
				event.setHTTPHeader(statusCode="203",statustext="ContentBoxCache Non-Authoritative Information")
					.setHTTPHeader(name="Content-type", value=data.contentType);
				// Store hits
				contentService.updateHits( data.contentID );
				// return cache content to be displayed
				return data.content;
			}
		}
		
		// execute the wrapped action
		arguments.action(event,rc,prc);
		
		// Check for missing page? If so, just return, no need to do multiple formats or caching for a missing page
		if( structKeyExists( prc, "missingPage" ) ){ return; }
		
		// Prepare data packet for rendering and caching and more
		var data = { content = "", contentID = "", contentType="text/html", isBinary=false };
		// generate content
		data.content = renderLayout(layout="#prc.cbLayout#/layouts/#layoutService.getThemePrintLayout(format=rc.format, layout=listLast(event.getCurrentLayout(),'/'))#", 
									module="contentbox",
									viewModule="contentbox");
		// Multi format generation
		switch( rc.format ){
			case "pdf" : {
				data.content 		= utility.marshallData(data=data.content, type="pdf");
				data.contentType 	= "application/pdf";
				data.isBinary 		= true;
				break;
			}
			case "doc" : {
				data.contentType = "application/msword";
				break;
			}
		}
		
		// Tell renderdata to render it
		event.renderData(data=data.content, contentType=data.contentType, isBinary=data.isBinary);
		
		// Get the content object
		var oContent = ( structKeyExists( prc, "page" ) ? prc.page : prc.entry ); 
		
		// verify if caching is possible by testing the content parameters
		if( cacheEnabled AND oContent.isLoaded() AND oContent.getCacheLayout() AND oContent.getIsPublished() ){
			// store page ID as we have it by now
			data.contentID = oContent.getContentID();
			// Cache data
			cache.set(cachekey,
					  data,
					  (oContent.getCacheTimeout() eq 0 ? prc.cbSettings.cb_content_cachingTimeout : oContent.getCacheTimeout()),
					  (oContent.getCacheLastAccessTimeout() eq 0 ? prc.cbSettings.cb_content_cachingTimeoutIdle : oContent.getCacheLastAccessTimeout()) );
		}
	}

	/**
	* Preview content page super event. Only called internally
	*/
	private function preview(event,rc,prc){
		// Param incoming data
		event.paramValue("content", "");
		event.paramValue("contentType", "");
		event.paramValue("layout", "");
		event.paramValue("title", "");
		event.paramValue("slug", "");
		event.paramValue("h", "");
		// Get all categories
		prc.categories = categoryService.list(sortOrder="category",asQuery=false);
		// get current author, only authors can preview
		prc.author = getModel("securityService@cb").getAuthorSession();
		// valid Author?
		if( !prc.author.isLoaded() OR !prc.author.isLoggedIn() OR compareNoCase( hash( prc.author.getAuthorID() ), rc.h) NEQ 0){
			// Not an author, kick them out.
			setNextEvent(URL=CBHelper.linkHome());
		}
	}
	
	/**
	* Validate incoming comment post
	*/
	private array function validateCommentPost(event,rc,prc,thisContent){
		var commentErrors = [];

		// param values
		event.paramValue("author","");
		event.paramValue("authorURL","");
		event.paramValue("authorEmail","");
		event.paramValue("content","");
		event.paramValue("captchacode","");

		// Check if comments enabled? else kick them out, who knows how they got here
		if( NOT CBHelper.isCommentsEnabled( thisContent ) ){
			getPlugin("MessageBox").warn("Comments are disabled! So you can't post any!");
			setNextEvent( URL=CBHelper.linkContent( thisContent ) );
		}

		// Trim values & XSS Cleanup of fields
		var antiSamy 	= getPlugin("AntiSamy");
		rc.author 		= antiSamy.htmlSanitizer( trim(rc.author) );
		rc.authorEmail 	= antiSamy.htmlSanitizer( trim(rc.authorEmail) );
		rc.authorURL 	= antiSamy.htmlSanitizer( trim(rc.authorURL) );
		rc.captchacode 	= antiSamy.htmlSanitizer( trim(rc.captchacode) );
		rc.content 		= antiSamy.htmlSanitizer( xmlFormat(trim(rc.content)) );

		// Validate incoming data
		commentErrors = [];
		if( !len(rc.author) ){ arrayAppend(commentErrors,"Your name is missing!"); }
		if( !len(rc.authorEmail) OR NOT validator.checkEmail(rc.authorEmail)){ arrayAppend(commentErrors,"Your email is missing or is invalid!"); }
		if( len(rc.authorURL) AND NOT validator.checkURL(rc.authorURL) ){ arrayAppend(commentErrors,"Your website URL is invalid!"); }
		if( !len(rc.content) ){ arrayAppend(commentErrors,"Your URL is invalid!"); }

		// Captcha Validation
		if( prc.cbSettings.cb_comments_captcha AND NOT getMyPlugin(plugin="Captcha",module="contentbox").validate( rc.captchacode ) ){
			ArrayAppend(commentErrors, "Invalid security code. Please try again.");
		}

		// announce event
		announceInterception("cbui_preCommentPost",{commentErrors=commentErrors,content=thisContent,contentType=thisContent.getContentType()});

		return commentErrors;
	}

	/**
	* Save the comment
	*/
	private function saveComment(thisContent){
		// Get new comment to persist
		var comment = populateModel( commentService.new() );
		// relate it to content
		comment.setRelatedContent( thisContent );
		// save it
		var results = commentService.saveComment( comment );

		// announce event
		announceInterception("cbui_onCommentPost",{comment=comment,content=thisContent,moderationResults=results,contentType=thisContent.getContentType()});

		// Check if all good
		if( results.moderated ){
			// Message
			getPlugin("MessageBox").warn(messageArray=results.messages);
			flash.put(name="commentErrors",value=results.messages,inflateTOPRC=true);
			// relocate back to comments
			setNextEvent(URL=CBHelper.linkComments( thisContent ));
		}
		else{
			// relocate back to comment
			setNextEvent(URL=CBHelper.linkComment( comment ));
		}
	}

}