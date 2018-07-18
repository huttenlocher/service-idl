/*
 * generated by Xtext 2.13.0
 */
package com.btc.serviceidl.tests

import com.btc.serviceidl.idl.IDLSpecification
import com.btc.serviceidl.tests.testdata.TestData
import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.eclipse.xtext.validation.Issue
import org.junit.Assert
import org.junit.Ignore
import org.junit.Test
import org.junit.runner.RunWith

import static com.google.common.collect.Iterables.isEmpty
import static extension com.btc.serviceidl.tests.TestExtensions.*

@RunWith(XtextRunner)
@InjectWith(IdlInjectorProvider)
class IdlParsingTest
{
    @Inject extension ParseHelper<IDLSpecification> parseHelper
    @Inject extension ValidationTestHelper
    @Inject Provider<ResourceSet> rsp

    @Test
    def void testExceptionDecl()
    {

        val rs = rsp.get()
        // TODO: Das muss noch Bestandteil der Grammatik werden
        rs.getResource(URI.createURI("src/com/btc/serviceidl/tests/testdata/base.idl"), true)

        val spec = '''
            // #include "base.idl"
            import BTC.Commons.Core.InvalidArgumentException
            
            module Test {
            
            interface KeyValueStore { 
            	exception DuplicateKeyException :  BTC.Commons.Core.InvalidArgumentException { 
            		string reason;
            	};
            	
            	foo() returns void raises DuplicateKeyException;
            };
            }
        '''.parse(rs)

        spec.assertNoErrors;

    /*
     * 		val exceptionDecl = ((spec.defintions.get(0) as module).defintions.get(0) as interface_decl).contains.get(0);
     * 		Assert::assertTrue("wrong type", exceptionDecl instanceof ExcecptionDecl);
     * 		Assert::assertEquals("DuplicateKeyException", (exceptionDecl as except_decl).name);
     */
    }

    @Ignore
    @Test
    def void testTemplates()
    {
        val spec = '''
            
            module Test {
            
            interface KeyValueStore { 
            
            	typedef string KeyType;
            	typedef string ValueType;
            	
            	typedef sequence<int32> IntSeq;
            };
            }
        '''.parse;

        spec.assertNoErrors;

//		val typedef = spec.defintions.get(0).module.defintions.get(0).interfaceDecl.contains.get(0).typeDecl.aliasType;
//		Assert::assertEquals("KeyType", typedef.name);
//		Assert::assertEquals("string", typedef.containedType.baseType.primitive.charstrType.stringType.PK_STRING);
    }

    @Test
    def void loadModel()
    {
        val result = parseHelper.parse('''
            module Test {}
        ''')
        Assert.assertNotNull(result)
        val errors = result.eResource.errors
        Assert.assertTrue('''Unexpected errors: «errors.join(", ")»''', errors.isEmpty)
    }

    @Test
    def void testFull()
    {
        val spec = TestData.full.parse;

        spec.assertNoErrors;
    }

    // copied from ValidationTestHelper, where doGetIssuesAsString and getIssuesAsString are protected unfortunately 
    static def StringBuilder doGetIssuesAsString(Resource spec, Iterable<Issue> issues, StringBuilder result)
    {
        for (issue : issues)
        {
            val uri = issue.getUriToProblem();
            result.append(issue.getSeverity());
            result.append(" (");
            result.append(issue.getCode());
            result.append(") '");
            result.append(issue.getMessage());
            result.append("'");
            if (uri !== null)
            {
                val eObject = spec.getResourceSet().getEObject(uri, true);
                result.append(" on ");
                result.append(eObject.eClass().getName());
            }
            result.append(", offset " + issue.getOffset() + ", length " + issue.getLength());
            result.append("\n");
        }
        return result;
    }

    static def StringBuilder getIssuesAsString(EObject model, Iterable<Issue> issues, StringBuilder result)
    {
        return doGetIssuesAsString(model.eResource(), issues, result);
    }

    static def StringBuilder getIssuesAsString(Resource resource, Iterable<Issue> issues, StringBuilder result)
    {
        // keep the original impl of #getIssuesAsString(EObject, ..) in the call graph  
        val contents = resource.getContents();
        if (contents.size() > 1)
        {
            return getIssuesAsString(contents.get(0), issues, result);
        }
        return doGetIssuesAsString(resource, issues, result);
    }

    // TODO this should be implemented as some parameterized test, but the XtextRunner does not support this. May the XpectRunner can be used instead 
    @Test
    def void testParsingSmokeTest()
    {
        doForEachTestCase(
            TestData.goodTestCases,
            [ testCase |
                val spec = testCase.value.parse
                val issues = validate(spec);
                if (!isEmpty(issues))
                    #["Test case '" + testCase.key + "': Expected no issues, but got :" +
                        getIssuesAsString(spec, issues, new StringBuilder())]
                else
                    #[]
            ]
        )
    }

}
