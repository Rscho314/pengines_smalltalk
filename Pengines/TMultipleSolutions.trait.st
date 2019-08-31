"
I provide data handling functions to Pengines querying predicates that return
multiple solutions (values of multiple variables).
"
Trait {
	#name : #TMultipleSolutions,
	#instVars : [
		'template',
		'server',
		'application',
		'ask',
		'chunk',
		'destroy',
		'src_text',
		'src_url',
		'format'
	],
	#category : #Pengines
}

{ #category : #settings }
TMultipleSolutions >> buildOptions [
	"We include 'template' in the options to allow for manipulation of the response"	
			
	^{ 	#server 				-> server.
			#application 	-> application.
	   	#ask 						-> ask.
			#template 			-> template.
			#chunk 				-> chunk.
			#destroy 			-> destroy.
			#src_text 			-> src_text.
			#src_url 			-> src_url.
			#format 				-> format } asDictionary
]

{ #category : #private }
TMultipleSolutions >> processData: someData [

	^someData do: [ :d | self onData: d ]
]

{ #category : #settings }
TMultipleSolutions >> template: aTemplate [
	"A Prolog variable (or a term containing Prolog variables) shared with the query.
	Meaningful only if the ask option is specified.
	By default the value of this option is the variable bindings of the query passed in the ask option (a list of Name=Var pairs).
	Variable names in the query starting with an underscore character will however not appear in the list."

	template := aTemplate
]
