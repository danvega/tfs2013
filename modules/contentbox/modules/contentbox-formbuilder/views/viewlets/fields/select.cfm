﻿<cfoutput>
	#prc.html.select(
		name=field.getName(),
		label=field.getLabel(),
		required=field.getIsRequired(),
		help=field.getHelpText(),
		id=field.getCSSID(),
		class=field.getCSSClass(),
		options=field.getFieldOptions(),
		column="actualValue",
		nameColumn="displayValue"
	)#
</cfoutput>