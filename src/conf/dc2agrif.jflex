package gr.agroknow.metadata.transformer.dc2agrif;

import gr.agroknow.metadata.agrif.Agrif;
import gr.agroknow.metadata.agrif.Citation;
import gr.agroknow.metadata.agrif.ControlledBlock;
import gr.agroknow.metadata.agrif.Creator;
import gr.agroknow.metadata.agrif.Expression;
import gr.agroknow.metadata.agrif.Item;
import gr.agroknow.metadata.agrif.LanguageBlock;
import gr.agroknow.metadata.agrif.Manifestation;
import gr.agroknow.metadata.agrif.Relation;
import gr.agroknow.metadata.agrif.Rights;
import gr.agroknow.metadata.agrif.Publisher;

import gr.agroknow.metadata.transformer.ParamManager;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;
import java.util.ArrayList;

import net.zettadata.generator.tools.Toolbox;
import net.zettadata.generator.tools.ToolboxException;

%%
%class DC2AGRIF
%standalone
%unicode

%{
	// AGRIF
	private List<Agrif> agrifs ;
	private Agrif agrif ;
	private Citation citation ;
	private ControlledBlock cblock ;
	private Creator creator ;
	private Expression expression ;
	private Item item ;
	private LanguageBlock lblock ;
	private Manifestation manifestation ;
	private Relation relation ;
	private Rights rights ;
	private Publisher publisher ;
	
	// TMP
	private StringBuilder tmp ;
	private String language ;
	private String date = null ;
	private List<Publisher> publishers = new ArrayList<Publisher>() ;
	
	// EXERNAL
	private String providerId ;
	private String manifestationType = "landingPage" ;
	
	public void setManifestationType( String manifestationType )
	{
		this.manifestationType = manifestationType ;
	}
	
	public void setProviderId( String providerId )
	{
		this.providerId = providerId ;
	}
	
	public List<Agrif> getAgrifs()
	{
		return agrifs ;
	}
	
	private void init()
	{
		agrif = new Agrif() ;
		agrif.setSet( ParamManager.getInstance().getSet() ) ;
		cblock = new ControlledBlock() ;
		expression = new Expression() ;
		citation = new Citation() ;
		citation.setTitle( "Archivos de Zootecnia" ) ;
		citation.setIdentifier( "issn", "1885 - 4494" ) ;
		expression.setCitation( citation ) ;
		// expression.setLanguage( "en" ) ;
		lblock = new LanguageBlock() ;
		rights = new Rights() ;
		rights.setRightsStatement( "en", "All rights reserved. This publication cannot be reproduced or transmitted, whole or partially, by any way, electronic or mechanically, not by photocopy, recording or another system of reproduction of information without written authorization of the holder of the rights of exploitation of the same one." ) ;
		agrif.setRights( rights ) ;
	}
		
	private String utcNow() 
	{
		Calendar cal = Calendar.getInstance();
		SimpleDateFormat sdf = new SimpleDateFormat( "yyyy-MM-dd" );
		return sdf.format(cal.getTime());
	}
	
	private String extract( String element )
	{	
		return element.substring(element.indexOf(">") + 1 , element.indexOf("</") );
	}
	
%}

%state AGRIF
%state DESCRIPTION
%state TITLE
%state CREATOR
%state SUBJECT

%%

<YYINITIAL>
{	
	
	"<oai-dc:dc"
	{
		agrifs = new ArrayList<Agrif>() ;
		init() ;
		yybegin( AGRIF ) ;
	}
}

<AGRIF>
{
	"</oai-dc:dc>"
	{
		agrif.setExpression( expression ) ;
		agrif.setLanguageBlocks( lblock ) ;
		agrif.setControlled( cblock ) ;
		agrifs.add( agrif ) ;
		yybegin( YYINITIAL ) ;
	}
	
	"<dc:language>".+"</dc:language>"
	{
		expression.setLanguage( extract(  yytext() ) ) ;
	}
	
	"<dc:title>"
	{
		tmp = new StringBuilder() ;
		yybegin( TITLE ) ;
	}

	"<dc:date>".+"</dc:date>"
	{
		date = extract( yytext() ) ;
		publisher = new Publisher() ;
		publisher.setDate( date ) ;
		publisher.setLocation( "Córdoba (España)" ) ;
		publisher.setName( "Asociación Iberoamericana de Zootecnia" ) ;
		expression.setPublisher( publisher ) ;
		publisher = new Publisher() ;
		publisher.setDate( date ) ;
		publisher.setName( "Universidad de Córdoba" ) ;
		publisher.setLocation( "Córdoba (España)" ) ;
		expression.setPublisher( publisher ) ;
	}

	"<dc:type>".+"</dc:type>"
	{
		String type = extract( yytext() ) ;
		cblock.setType( "dcterms", type ) ;
	}
	
		
	"<dc:identifier>".+"</dc:identifier>"
	{
		manifestation = new Manifestation() ;
		item = new Item() ;
		item.setDigitalItem( extract( yytext() ) ) ;
		manifestation.setManifestationType( "fullText" ) ;
		manifestation.setFormat( "text/html" ) ;
		manifestation.setItem( item ) ;
		expression.setManifestation( manifestation ) ;
	}

	"<dc:creator>"
	{
		yybegin( CREATOR ) ;
		tmp = new StringBuilder() ;
	}
	
	
	"<dc:subject>"
	{
		yybegin( SUBJECT ) ;
		tmp = new StringBuilder() ;
	}
	
	"<dc:description>"
	{
		tmp = new StringBuilder() ;
		yybegin( DESCRIPTION ) ;
	}
	
}

<CREATOR>
{
	"</dc:creator>"
	{
		creator = new Creator() ;
		creator.setName( tmp.toString() ) ;
		creator.setType( "person" ) ;
		agrif.setCreator( creator ) ;
		yybegin( AGRIF ) ;
	}

	"<![CDATA["|"]]>"
	{
		//ignore
	}
	
	.
	{
		tmp.append( yytext() ) ;	
	}
}

<SUBJECT>
{
	"</dc:subject>"
	{
		String tmptext = tmp.toString() ;
		language = ParamManager.getInstance().getLanguageFor( tmptext ) ;
		lblock.setKeyword( language, tmptext ) ;
		yybegin( AGRIF ) ;
	}
	

	"<![CDATA["|"]]>"
	{
		// ignore !
	}
	
	.
	{
		tmp.append( yytext() ) ; 
	}
	
	\n
	{
		tmp.append( " " ) ;
	}
}



<TITLE>
{
	"</dc:title>"
	{
		String tmptext = tmp.toString() ;
		language = ParamManager.getInstance().getLanguageFor( tmptext ) ;
		yybegin( AGRIF ) ;
		lblock.setTitle( language, tmptext ) ;
	}
	
	"<![CDATA["|"]]>"
	{
		// ignore !
	}
	
	.
	{
		tmp.append( yytext() ) ; 
	}
	
	\n
	{
		tmp.append( " " ) ;
	}

}

<DESCRIPTION>
{
	"</dc:description>"
	{
		yybegin( AGRIF ) ;
		String tmptext = tmp.toString() ;
		language = ParamManager.getInstance().getLanguageFor( tmptext ) ;
		lblock.setAbstract( language, tmptext ) ;
	}
		
	"<![CDATA["|"]]>"
	{
		// ignore !
	}
	
	.
	{
		tmp.append( yytext() ) ; 
	}
	
	\n
	{
		tmp.append( " " ) ;
	}
}

/* error fallback */
.|\n 
{
	//throw new Error("Illegal character <"+ yytext()+">") ;
}
