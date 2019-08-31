"
I provide data handling functions to Pengines querying predicates that return
single solutions (values of a single variable).
"
Trait {
	#name : #TSingleSolution,
	#instVars : [
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
TSingleSolution >> buildOptions [
	"We include 'template' in the options to allow for manipulation of the response"	
			
	^{ 	#server 				-> server.
			#application 	-> application.
	   	#ask 						-> ask.
			#chunk 				-> chunk.
			#destroy 			-> destroy.
			#src_text 			-> src_text.
			#src_url 			-> src_url.
			#format 				-> format } asDictionary
]

{ #category : #private }
TSingleSolution >> processData: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onData: someData
]
