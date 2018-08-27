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
/*
 * generated by Xtext 2.13.0
 */
package com.btc.serviceidl.generator;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.Path;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.xtext.diagnostics.Severity;
import org.eclipse.xtext.generator.GeneratorContext;
import org.eclipse.xtext.generator.GeneratorDelegate;
import org.eclipse.xtext.generator.JavaIoFileSystemAccess;
import org.eclipse.xtext.util.CancelIndicator;
import org.eclipse.xtext.validation.CheckMode;
import org.eclipse.xtext.validation.IResourceValidator;
import org.eclipse.xtext.validation.Issue;

import com.btc.serviceidl.IdlStandaloneSetup;
import com.btc.serviceidl.generator.common.ArtifactNature;
import com.google.inject.Inject;
import com.google.inject.Injector;
import com.google.inject.Provider;

public class Main {

    public static final String OPTION_OUTPUT_PATH                            = "outputPath";
    public static final String OPTION_CPP_OUTPUT_PATH                        = "cppOutputPath";
    public static final String OPTION_JAVA_OUTPUT_PATH                       = "javaOutputPath";
    public static final String OPTION_DOTNET_OUTPUT_PATH                     = "dotnetOutputPath";
    public static final String OPTION_CPP_PROJECT_SYSTEM                     = "cppProjectSystem";
    public static final String OPTION_VALUE_CPP_PROJECT_SYSTEM_CMAKE         = "cmake";
    public static final String OPTION_VALUE_CPP_PROJECT_SYSTEM_PRINS_VCXPROJ = "prins-vcxproj";
    public static final String OPTION_VERSIONS                               = "versions";
    public static final String OPTION_PROJECT_SET                            = "projectSet";
    public static final String OPTION_MATURITY                               = "maturity";
    public static final String OPTION_VALUE_MATURITY_SNAPSHOT                = "snapshot";
    public static final String OPTION_VALUE_MATURITY_RELEASE                 = "release";

    public static final int EXIT_CODE_GOOD              = 0;
    public static final int EXIT_CODE_GENERATION_FAILED = 1;
    public static final int EXIT_CODE_INVALID_ARGUMENTS = 1;

    public static void main(String[] args) {
        System.exit(mainBackend(args));
    }

    public static int mainBackend(String[] args) {
        assert (args != null);
        if (args.length == 0) {
            new HelpFormatter().printHelp("Generator", createOptions());
            System.err.println("Aborting: no path to EMF resource provided!");
            return EXIT_CODE_INVALID_ARGUMENTS;
        }
        Injector injector = new IdlStandaloneSetup().createInjectorAndDoEMFRegistration();
        Main main = injector.getInstance(Main.class);

        CommandLine commandLine = parseCommandLine(args);
        if (commandLine == null) return 1;

        if (commandLine.getArgs().length == 0) {
            System.err.println("No input files specified.");
            return 1;
        }

        final boolean genericOutputPath = commandLine.hasOption(OPTION_OUTPUT_PATH);
        final boolean specificOutputPath = commandLine.hasOption(OPTION_CPP_OUTPUT_PATH)
                || commandLine.hasOption(OPTION_JAVA_OUTPUT_PATH) || commandLine.hasOption(OPTION_DOTNET_OUTPUT_PATH);

        if (genericOutputPath == specificOutputPath) {
            System.err.println("You must specify *either* a generic output path using -" + OPTION_OUTPUT_PATH
                    + ", or one or more technology-specific output paths using -" + OPTION_CPP_OUTPUT_PATH + ", -"
                    + OPTION_JAVA_OUTPUT_PATH + ", -" + OPTION_DOTNET_OUTPUT_PATH);
            return EXIT_CODE_INVALID_ARGUMENTS;
        }
        // TODO this might need to be moved somewhere else, or at least be changed such
        // that in case of a generic output path the set of languages from a config file
        // is not overridden
        Map<ArtifactNature, IPath> outputPaths = new HashMap<ArtifactNature, IPath>();
        if (genericOutputPath) {
            IPath baseOutputPath = new Path(commandLine.getOptionValue(OPTION_OUTPUT_PATH));
            for (ArtifactNature artifactNature : ArtifactNature.values()) {
                outputPaths.put(artifactNature, baseOutputPath.append(artifactNature.getLabel()));
            }
        } else {
            if (commandLine.hasOption(OPTION_CPP_OUTPUT_PATH)) {
                outputPaths.put(ArtifactNature.CPP, new Path(commandLine.getOptionValue(OPTION_CPP_OUTPUT_PATH)));
            }
            if (commandLine.hasOption(OPTION_JAVA_OUTPUT_PATH)) {
                outputPaths.put(ArtifactNature.JAVA, new Path(commandLine.getOptionValue(OPTION_JAVA_OUTPUT_PATH)));
            }
            if (commandLine.hasOption(OPTION_DOTNET_OUTPUT_PATH)) {
                outputPaths.put(ArtifactNature.DOTNET, new Path(commandLine.getOptionValue(OPTION_DOTNET_OUTPUT_PATH)));
            }
        }

        final boolean res = main.tryRunGenerator(commandLine.getArgs(), outputPaths,
                commandLine.hasOption(OPTION_CPP_PROJECT_SYSTEM) ? commandLine.getOptionValue(OPTION_CPP_PROJECT_SYSTEM)
                        : null,
                commandLine.hasOption(OPTION_VERSIONS) ? commandLine.getOptionValue(OPTION_VERSIONS) : null,
                commandLine.hasOption(OPTION_PROJECT_SET) ? commandLine.getOptionValue(OPTION_PROJECT_SET) : null,
                commandLine.hasOption(OPTION_MATURITY) ? commandLine.getOptionValue(OPTION_MATURITY) : null);

        return res ? EXIT_CODE_GOOD : EXIT_CODE_GENERATION_FAILED;
    }

    private static Options createOptions() {
        Options options = new Options();
        options.addOption(OPTION_OUTPUT_PATH, true, "base path for generated output files (all technologies)");
        options.addOption(OPTION_CPP_OUTPUT_PATH, true, "base path for generated C++ output files");
        options.addOption(OPTION_JAVA_OUTPUT_PATH, true, "base path for generated Java output files");
        options.addOption(OPTION_DOTNET_OUTPUT_PATH, true, "base path for generated .NET output files");
        options.addOption(OPTION_CPP_PROJECT_SYSTEM, true, "C++ project system ("
                + OPTION_VALUE_CPP_PROJECT_SYSTEM_CMAKE + "," + OPTION_VALUE_CPP_PROJECT_SYSTEM_PRINS_VCXPROJ + ")");
        options.addOption(OPTION_VERSIONS, true, "target Version overrides");
        options.addOption(OPTION_PROJECT_SET, true, "set of projects to generate ("
                + String.join(",", DefaultGenerationSettingsProvider.PROJECT_SET_MAPPING.keySet()) + "), default is "
                + DefaultGenerationSettingsProvider.OPTION_VALUE_PROJECT_SET_FULL_WITH_SKELETON);
        options.addOption(OPTION_MATURITY, true, "maturity (snapshot, release) (default is snapshot)");
        return options;
    }

    private static CommandLine parseCommandLine(String[] args) {
        CommandLineParser parser = new GnuParser();
        try {
            return parser.parse(createOptions(), args);
        } catch (ParseException exp) {
            System.err.println("Parsing command line failed.  Reason: " + exp.getMessage());
            return null;
        }
    }

    @Inject
    private Provider<ResourceSet> resourceSetProvider;

    @Inject
    private IResourceValidator validator;

    @Inject
    private GeneratorDelegate generator;

    @Inject
    private JavaIoFileSystemAccess fileAccess;

    @Inject
    private IGenerationSettingsProvider generationSettingsProvider;

    private boolean tryRunGenerator(String[] inputFiles, Map<ArtifactNature, IPath> outputPaths,
            String cppProjectSystem, String versions, String projectSet, String maturityString) {
        // Load the resource
        ResourceSet set = resourceSetProvider.get();
        for (String inputFile : inputFiles) {
            set.getResource(URI.createFileURI(inputFile), true);
        }

        System.out.println("Validating IDL input.");
        for (Resource resource : set.getResources()) {

            // Validate the resources
            List<Issue> list = validator.validate(resource, CheckMode.ALL, CancelIndicator.NullImpl);
            if (!list.isEmpty()) {
                boolean hasError = false;
                for (Issue issue : list) {
                    System.err.println(issue);
                    hasError |= issue.getSeverity() == Severity.ERROR;
                }
                if (hasError) {
                    System.err.println("Errors in IDL input, terminating.");
                    return false;
                }
            }
        }
        System.out.println("IDL input is valid.");

        for (ArtifactNature artifactNature : outputPaths.keySet()) {
            final IPath outputPath = outputPaths.get(artifactNature);
            System.out
                    .println("Configuring generation of " + artifactNature.getLabel() + " artifacts to " + outputPath);
            fileAccess.setOutputPath(artifactNature.getLabel(), outputPath.toOSString());
        }

        Maturity maturity = Maturity.SNAPSHOT;
        if (maturityString != null) {
            if (maturityString.equals(OPTION_VALUE_MATURITY_RELEASE))
                maturity = Maturity.RELEASE;
            else if (maturityString.equals(OPTION_VALUE_MATURITY_SNAPSHOT))
                maturity = Maturity.SNAPSHOT;
            else {
                throw new IllegalArgumentException(
                        "Unknown value for option '" + OPTION_MATURITY + "': " + maturityString);
            }
        }

        try {
            configureGenerationSettings(cppProjectSystem, versions, outputPaths.keySet(), projectSet, maturity);
        } catch (Exception ex) {
            System.err.println("Error when configuring generation settings: " + ex);
            return false;
        }

        // Start the generator
        GeneratorContext context = new GeneratorContext();
        context.setCancelIndicator(CancelIndicator.NullImpl);

        for (Resource resource : set.getResources()) {
            generator.generate(resource, fileAccess, context);
        }

        System.out.println("Code generation finished.");
        return true;
    }

    private void configureGenerationSettings(String cppProjectSystem, String versions,
            Iterable<ArtifactNature> languages, String projectSet, Maturity maturity) {
        DefaultGenerationSettingsProvider defaultGenerationSettingsProvider = (DefaultGenerationSettingsProvider) generationSettingsProvider;

        defaultGenerationSettingsProvider.configureGenerationSettings(cppProjectSystem, versions, languages, projectSet,
                maturity);
    }

}
