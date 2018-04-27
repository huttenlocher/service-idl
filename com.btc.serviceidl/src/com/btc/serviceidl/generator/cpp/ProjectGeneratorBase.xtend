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
package com.btc.serviceidl.generator.cpp

import com.btc.serviceidl.generator.common.ArtifactNature
import com.btc.serviceidl.generator.common.GeneratorUtil
import com.btc.serviceidl.generator.common.ParameterBundle
import com.btc.serviceidl.generator.common.ProjectType
import com.btc.serviceidl.generator.common.TransformType
import com.btc.serviceidl.idl.InterfaceDeclaration
import com.btc.serviceidl.util.Constants
import org.eclipse.xtend.lib.annotations.Accessors

import static extension com.btc.serviceidl.generator.common.FileTypeExtensions.*
import static extension com.btc.serviceidl.util.Util.*

@Accessors(PROTECTED_GETTER)
abstract class ProjectGeneratorBase extends ProjectGeneratorBaseBase
{
    // TODO align the method signatures: either both should be passed a BasicCppGenerator or none, the order of parameters should also be aligned
    interface ISourceGenerationStrategy
    {
        def String generateProjectSource(BasicCppGenerator basicCppGenerator,
            InterfaceDeclaration interface_declaration)

        def String generateProjectHeader(BasicCppGenerator basicCppGenerator,
            InterfaceDeclaration interface_declaration, String export_header)
    }

    val ISourceGenerationStrategy sourceGenerationStrategy

    def protected void generate()
    {
        // TODO check how to reflect this special handling of EXTERNAL_DB_IMPL
//        if (project_type != ProjectType.EXTERNAL_DB_IMPL) // for ExternalDBImpl, keep both C++ and ODB artifacts
//            reinitializeProject(project_type)
        val export_header_file_name = (GeneratorUtil.getTransformedModuleName(param_bundle, ArtifactNature.CPP,
            TransformType.EXPORT_HEADER) + "_export".h).toLowerCase
        file_system_access.generateFile(projectPath + "include" + Constants.SEPARATOR_FILE + export_header_file_name,
            generateExportHeader())
        header_files.add(export_header_file_name)

        for (interface_declaration : module.moduleComponents.filter(InterfaceDeclaration))
        {
            generateProject(param_bundle.projectType, interface_declaration, projectPath, export_header_file_name)
        }

        val dependency_file_name = Constants.FILE_NAME_DEPENDENCIES.cpp
        file_system_access.generateFile(projectPath + "source" + Constants.SEPARATOR_FILE + dependency_file_name,
            generateDependencies())
        dependency_files.add(dependency_file_name)

        if (param_bundle.projectType != ProjectType.EXTERNAL_DB_IMPL) // done separately for ExternalDBImpl to include ODB files also
        {
            generateVSProjectFiles(param_bundle.projectType, projectPath, vsSolution.getVcxprojName(param_bundle))
        }
    }

    def private void generateProject(ProjectType pt, InterfaceDeclaration interface_declaration, String project_path,
        String export_header_file_name)
    {
        val builder = new ParameterBundle.Builder(param_bundle)
        builder.reset(interface_declaration.moduleStack)
        val localParamBundle = builder.build

        // paths
        val include_path = project_path + "include" + Constants.SEPARATOR_FILE
        val source_path = project_path + "source" + Constants.SEPARATOR_FILE

        // file names
        val main_header_file_name = GeneratorUtil.getClassName(ArtifactNature.CPP, localParamBundle.projectType,
            interface_declaration.name).h
        val main_cpp_file_name = GeneratorUtil.getClassName(ArtifactNature.CPP, localParamBundle.projectType,
            interface_declaration.name).cpp

        // sub-folder "./include"
        if (pt != ProjectType.TEST)
        {
            file_system_access.generateFile(include_path + Constants.SEPARATOR_FILE + main_header_file_name,
                sourceGenerationStrategy.generateProjectHeader(createBasicCppGenerator(localParamBundle),
                    interface_declaration, export_header_file_name))
            header_files.add(main_header_file_name)
        }

        // sub-folder "./source"
        file_system_access.generateFile(source_path + main_cpp_file_name,
            sourceGenerationStrategy.generateProjectSource(createBasicCppGenerator(localParamBundle),
                interface_declaration))
        cpp_files.add(main_cpp_file_name)
    }

    // TODO move this somewhere else
    def protected static generateCppImpl(TypeResolver typeResolver, ParameterBundle paramBundle,
        InterfaceDeclaration interface_declaration)
    {
        new ImplementationStubGenerator(typeResolver, paramBundle).generateCppImpl(interface_declaration)
    }

    // TODO move this somewhere else
    def protected static generateInterface(TypeResolver typeResolver, ParameterBundle paramBundle,
        InterfaceDeclaration interface_declaration)
    {
        new ServiceAPIGenerator(typeResolver, paramBundle).generateHeaderFileBody(interface_declaration)
    }

}
