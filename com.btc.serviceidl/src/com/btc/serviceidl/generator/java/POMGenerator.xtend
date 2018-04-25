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
package com.btc.serviceidl.generator.java

import org.eclipse.emf.ecore.EObject
import java.util.Optional

class POMGenerator
{
    def public static String generatePOMContents(EObject container, Iterable<MavenDependency> dependencies,
        String protobuf_file)
    {
        val root_name = MavenResolver.resolvePackage(container, Optional.empty)
        val version = MavenResolver.resolveVersion(container)

        '''
            <project xmlns="http://maven.apache.org/POM/4.0.0"
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                     xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                                         http://maven.apache.org/xsd/maven-4.0.0.xsd">
            
               <modelVersion>4.0.0</modelVersion>
            
               <groupId>«root_name»</groupId>
               <artifactId>«root_name»</artifactId>
               <version>«version»</version>
            
               <properties>
               <!-- ServiceComm properties -->
               <servicecomm.version>0.3.0</servicecomm.version>
               
               <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
               <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
               
               <maven.compiler.source>1.8</maven.compiler.source>
               <maven.compiler.target>1.8</maven.compiler.target>
               
               <!-- directory for files generated by the protoc compiler (default = /src/main/java) -->
               <protobuf.outputDirectory>${project.build.sourceDirectory}</protobuf.outputDirectory>
               <!-- *.proto source files (default = /src/main/proto) -->
               <protobuf.sourceDirectory>${basedir}/src/main/proto</protobuf.sourceDirectory>
               <!-- directory containing the protoc executable (default = %PROTOC_HOME% environment variable) -->
               <protobuf.binDirectory>${PROTOC_HOME}</protobuf.binDirectory>
               </properties>
               
               <repositories>
                  <repository>
                     <id>cab-maven-resolver</id>
                     <url>http://artifactory.inf.bop/artifactory/cab-maven-resolver//</url>
                     <releases>
                        <enabled>true</enabled>
                     </releases>
                     <snapshots>
                         <enabled>false</enabled>
                     </snapshots>
                  </repository>
               </repositories>
               
               <distributionManagement>
                  <repository>
                     <id>cab-maven</id>
                     <name>CAB Main Maven Repository</name>
                     <url>http://artifactory.inf.bop/artifactory/cab-maven/</url>
                  </repository>
               </distributionManagement>
               
               <dependencies>
                  «FOR dependency : dependencies.filter[ artifactId != root_name ]»
                      <dependency>
                         <groupId>«dependency.groupId»</groupId>
                         <artifactId>«dependency.artifactId»</artifactId>
                         <version>«dependency.version»</version>
                         «IF dependency.scope !== null»
                             <scope>«dependency.scope»</scope>
                         «ENDIF»
                      </dependency>
                  «ENDFOR»
               </dependencies>
            
               <build>
               <pluginManagement>
                  <plugins>
                     <plugin>
                        <groupId>org.eclipse.m2e</groupId>
                        <artifactId>lifecycle-mapping</artifactId>
                        <version>1.0.0</version>
                        <configuration>
                           <lifecycleMappingMetadata>
                              <pluginExecutions>
                                 <pluginExecution>
                                    <pluginExecutionFilter>
                                       <groupId>org.apache.maven.plugins</groupId>
                                       <artifactId>maven-antrun-plugin</artifactId>
                                       <versionRange>[1.0.0,)</versionRange>
                                       <goals>
                                          <goal>run</goal>
                                       </goals>
                                    </pluginExecutionFilter>
                                    <action>
                                       <execute />
                                    </action>
                                 </pluginExecution>
                              </pluginExecutions>
                           </lifecycleMappingMetadata>
                        </configuration>
                     </plugin>
                  </plugins>
               </pluginManagement>
               <plugins>
                  <plugin>
                     <groupId>org.apache.maven.plugins</groupId>
                     <artifactId>maven-antrun-plugin</artifactId>
                     <version>1.8</version>
                     <executions>
                        <execution>
                           <id>generate-sources</id>
                           <phase>generate-sources</phase>
                           <configuration>
                              <target>
                                 <mkdir dir="${protobuf.outputDirectory}" />
                                 <exec executable="${protobuf.binDirectory}/protoc">
                                    <arg value="--java_out=${protobuf.outputDirectory}" />
                                    <arg value="-I=${basedir}\.." />
                                    <arg value="--proto_path=${protobuf.sourceDirectory}" />
                                    «IF protobuf_file !== null»
                                        <arg value="${protobuf.sourceDirectory}/«protobuf_file».proto" />
                                    «ENDIF»
                                 </exec> 
                              </target>
                           </configuration>
                           <goals>
                              <goal>run</goal>
                           </goals>
                        </execution>
                     </executions>
                  </plugin>
                  <plugin>
                     <groupId>org.apache.maven.plugins</groupId>
                     <artifactId>maven-compiler-plugin</artifactId>
                     <version>3.3</version>
                     <configuration>
                        <source>1.8</source>
                        <target>1.8</target>
                     </configuration>
                  </plugin>
               </plugins>
               </build>
            
            </project>
        '''
    }
}
