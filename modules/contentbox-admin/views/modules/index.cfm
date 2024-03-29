﻿<cfoutput>
<div class="row-fluid">
	<!--- main content --->
	<div class="span9" id="main-content">
		<div class="box">
			
			<!--- Body Header --->
			<div class="header">
				<ul class="sub_nav nav nav-tabs">
					<!--- Manage --->
					<li class="active" title="Manage Modules"><a href="##managePane" data-toggle="tab"><i class="icon-cog icon-large"></i> Manage</a></li>
					<cfif prc.oAuthor.checkPermission("FORGEBOX_ADMIN")>
					<!--- Install --->
					<li title="Install New Modules"><a href="##forgeboxPane" data-toggle="tab" onclick="loadForgeBox()"><i class="icon-cloud-download icon-large"></i> ForgeBox</a></li>
					</cfif>
				</ul>
				
				<!--- Title --->
				<i class="icon-bolt icon-large"></i>
				Modules
			</div>
			
			<!--- Body --->
			<div class="body">
	
				<!--- MessageBox --->
				#getPlugin("MessageBox").renderit()#
	
				<!--- Logs --->
				<cfif flash.exists("forgeboxInstallLog")>
					<h3>Installation Log</h3>
					<div class="consoleLog">#flash.get("forgeboxInstallLog")#</div>
				</cfif>
	
				<div class="panes tab-content">
					
					<div id="managePane" class="tab-pane active">
					<!--- CategoryForm --->
					#html.startForm(name="moduleForm")#
					#html.hiddenField(name="moduleName")#
	
					<!--- Content Bar --->
					<div class="well well-small">
						<!--- Filter Bar --->
						<div class="filterBar">
							<div>
								#html.label(field="moduleFilter",content="Quick Filter:",class="inline")#
								#html.textField(name="moduleFilter",size="30",class="textfield")#
							</div>
						</div>
					</div>
	
					<!--- modules --->
					<table name="modules" id="modules" class="tablesorter table table-hover table-striped" width="98%">
						<thead>
							<tr>
								<th>Module</th>
								<th>Description</th>
								<th class="center">Activated</th>
								<th width="100" class="center {sorter:false}">Actions</th>
							</tr>
						</thead>
						<tbody>
							<cfloop array="#prc.modules#" index="module">
							<tr <cfif !module.getIsActive()>class="warning"</cfif>>
								<td>
									<strong>#module.getTitle()#</strong><br/>
									Version #module.getVersion()#
									By <a href="#module.getWebURL()#" target="_blank" title="#module.getWebURL()#">#module.getAuthor()#</a>
								</td>
								<td>
									#module.getDescription()#<br/>
									<cfif len( module.getForgeBoxSlug() )>
									ForgeBox URL: <a href="#prc.forgeBoxEntryURL & "/" & module.getForgeBoxSlug()#" target="_blank">#module.getForgeBoxSlug()#</a>
									</cfif>
								</td>
								<td class="center">
									<cfif module.getIsActive()>
										<i class="icon-ok icon-large textGreen"></i>
										<span class="hidden">active</span>
									<cfelse>
										<i class="icon-remove icon-large textRed"></i>
										<span class="hidden">deactivated</span>
									</cfif>
								</td>
								<td class="center">
								<cfif prc.oAuthor.checkPermission("MODULES_ADMIN")>
									<div class="btn-group">
									<!--- Check if active --->
									<cfif module.getIsActive()>
										<!--- Update Check --->
										<a class="btn" title="Deactivate Module" href="javascript:deactivate('#JSStringFormat(module.getName())#')"><i class="icon-thumbs-down icon-large"></i></a>
										&nbsp;
									<cfelse>
										<a class="btn" title="Activate Module" href="javascript:activate('#JSStringFormat(module.getName())#')"><i class="icon-thumbs-up icon-large"></i></a>
										&nbsp;
										<!--- Delete Module --->
										<a class="btn" title="Delete Module" href="javascript:remove('#JSStringFormat(module.getName())#')" class="confirmIt"
											data-title="Delete #module.getName()#?"><i class="icon-trash icon-large"></i></a>
									</cfif>
									</div>
								</cfif>
								</td>
							</tr>
							</cfloop>
						</tbody>
					</table>
	
					#html.endForm()#
					</div>
					<!--- end manage pane --->
	
					<cfif prc.oAuthor.checkPermission("MODULES_ADMIN")>
					<!--- ForgeBox --->
					<div id="forgeboxPane" class="tab-pane">
						<div class="center">
							<i class="icon-spinner icon-spin icon-large icon-4x"></i><br/>
							Please wait, connecting to ForgeBox...
						</div>
					</div>
					</cfif>
	
				<!--- end panes --->
			</div>
			<!--- end body --->
		</div>
		</div>
	</div>

	<!--- main sidebar --->
	<div class="span3" id="main-sidebar">
		<cfif prc.oAuthor.checkPermission("MODULES_ADMIN")>
		<!--- Actions Box --->
		<div class="small_box">
			<div class="header">
				<i class="icon-cogs"></i> Module Admin Actions
			</div>
			<div class="body text-center">
				<div class="btn-group">
				<a href="#event.buildLink(prc.xehModuleReset)#" title="Deactivate + Rescan" class="btn"><i class="icon-hdd"></i> Reset</a>
				<a href="#event.buildLink(prc.xehModuleRescan)#" title="Scans For New Modules" class="btn"><i class="icon-refresh"></i> Rescan</a>
				</div>
			</div>
		</div>
		<!--- Upload Box --->
		<div class="small_box">
			<div class="header">
				<i class="icon-upload-alt"></i> Module Uploader
			</div>
			<div class="body">
				#html.startForm(name="moduleUploadForm",action=prc.xehModuleUpload,multipart=true,novalidate="novalidate")#
	
					#html.fileField(name="fileModule",label="Upload Module: ", class="input-block-level",required="required")#
	
					<div class="actionBar" id="uploadBar">
						#html.submitButton(value="Upload & Install",class="btn btn-danger")#
					</div>
	
					<!--- Loader --->
					<div class="loaders" id="uploadBarLoader">
						<i class="icon-spinner icon-spin icon-large icon-2x"></i> Uploading...
					</div>
				#html.endForm()#
			</div>
		</div>
		</cfif>
	</div>
</div>
</cfoutput>