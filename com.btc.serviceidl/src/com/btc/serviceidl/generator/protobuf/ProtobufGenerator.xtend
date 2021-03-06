/*********************************************************************
* \author see AUTHORS file
* \copyright 2015-2018 BTC Business Technology Consulting AG and others
*
* This program and the accompanying materials are made
* available under the terms of the Eclipse Public License 2.0
* which is available at https://www.eclipse.org/legal/epl-2.0/
*
* SPDX-License-Identifier: EPL-2.0
**********************************************************************/
/**
 * \file       ProtobufGenerator.xtend
 * 
 * \brief      Xtend generator for Google Protocol Buffers artifacts from an IDL
 */

package com.btc.serviceidl.generator.protobuf

import com.btc.serviceidl.generator.common.ArtifactNature
import com.btc.serviceidl.generator.common.ParameterBundle
import com.btc.serviceidl.generator.cpp.IModuleStructureStrategy
import com.btc.serviceidl.idl.AbstractContainerDeclaration
import com.btc.serviceidl.idl.InterfaceDeclaration
import com.btc.serviceidl.idl.ModuleDeclaration
import com.btc.serviceidl.util.Constants
import java.util.HashMap
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.naming.IQualifiedNameProvider

import static com.btc.serviceidl.generator.protobuf.ProtobufGeneratorUtil.*

@Accessors(NONE)
final class ProtobufGenerator
{
   val Resource resource
   val IFileSystemAccess fileSystemAccess
   val IQualifiedNameProvider qualifiedNameProvider
   val IModuleStructureStrategy moduleStructureStrategy
      
   val generatedArtifacts = new HashMap<AbstractContainerDeclaration, String>
   val typedefTable = new HashMap<String, String>
   val allProjectReferences = new HashMap<ArtifactNature, Map<ParameterBundle, Set<ParameterBundle>>>
   
   def Map<ParameterBundle, Set<ParameterBundle>> getProjectReferences(ArtifactNature artifactNature)
    {
        allProjectReferences.computeIfAbsent(artifactNature, [new HashMap<ParameterBundle, Set<ParameterBundle>>])
    }
   
   def Map<AbstractContainerDeclaration, String> getGeneratedArtifacts()
   {
      return generatedArtifacts
   }
   
    def void doGenerate(Iterable<ArtifactNature> languages) 
    {  
      // handle all interfaces
      for (interfaceDeclaration : resource.allContents.filter(InterfaceDeclaration).toIterable)
      {
          generateProtobufFileForEachLanguage(languages, interfaceDeclaration, interfaceDeclaration.name,
                 [language|new InterfaceProtobufFileGenerator(qualifiedNameProvider, moduleStructureStrategy,
                     getProjectReferences(language), typedefTable, language).generateInterface(
                     interfaceDeclaration)])
      }
      
      // handle all module contents (excluding interfaces)
      for (module : resource.allContents.filter(ModuleDeclaration).filter[!isVirtual].toIterable)
      {
         val moduleContents = module.eContents.reject[it instanceof AbstractContainerDeclaration]
         if ( !moduleContents.empty )
         {
             generateProtobufFileForEachLanguage(languages, module, Constants.FILE_NAME_TYPES, 
                 [language|new ModuleProtobufFileGenerator(qualifiedNameProvider, moduleStructureStrategy,
                            getProjectReferences(language), typedefTable, language).generateModuleContent(module,
                            moduleContents)])
         }
      }
   }
   
   private def void generateProtobufFileForEachLanguage(Iterable<ArtifactNature> languages, AbstractContainerDeclaration object,
        String artifactName, (ArtifactNature)=>CharSequence generateContent)
    {
         // TODO why is the proto file generated for each language?
        for (language : languages)
            generateProtobufFile(language, object, artifactName, generateContent.apply(language))

        generatedArtifacts.put(object, artifactName)
    }
   
   private def void generateProtobufFile(ArtifactNature artifactNature, AbstractContainerDeclaration container, String artifactName,
        CharSequence fileContent)
    {
        fileSystemAccess.generateFile(
            makeProtobufPath(container, artifactName, artifactNature, moduleStructureStrategy).toPortableString,
            artifactNature.label, fileContent)
    }
}
