#!/usr/bin/ruby
# 
# This is an abstract test case class for building Test::Unit unit tests for the
# WordNet class library. It consolidates most of the maintenance work that
# must be done to build a test file by adjusting the $LOAD_PATH to include the
# lib/ and ext/ directories, as well as adding some other useful methods that
# make building and maintaining the tests much easier (IMHO). See the docs for
# Test::Unit for more info on the particulars of unit testing.
# 
# == Synopsis
# 
#	# Allow the unit test to be run from the base dir, or from tests/ or
#	# similar:
#	begin
#		require 'tests/fmtestcase'
#	rescue
#		require '../fmtestcase'
#	end
#
#	class MySomethingTest < WordNet::TestCase
#		def setup
#			super()
#			@foo = 'bar'
#		end
#
#		def test_00_something
#			obj = nil
#			assert_nothing_raised { obj = MySomething::new }
#			assert_instance_of MySomething, obj
#			assert_respond_to :myMethod, obj
#		end
#	end
# 
# == Rcsid
# 
# $Id: wntestcase.rb,v 1.1 2003/08/06 08:05:39 deveiant Exp $
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# Copyright (c) 2002, 2003 The FaerieMUD Consortium. All rights reserved.
# 
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
#

begin
	basedir = File::dirname( File::dirname(__FILE__) )
	unless $LOAD_PATH.include?( "#{basedir}/lib" )
		$LOAD_PATH.unshift "#{basedir}/lib"
	end
end

require "test/unit"
require "test/unit/mock"
require "wordnet"

module WordNet

	### The abstract base class for WordNet test cases.
	class TestCase < Test::Unit::TestCase

		class << self
			@methodCounter = 0
			attr_accessor :methodCounter
		end


		### Inheritance callback -- adds @setupBlocks and @teardownBlocks ivars
		### and accessors to the inheriting class.
		def self::inherited( klass )
			klass.module_eval {
				@setupBlocks = []
				@teardownBlocks = []

				class << self
					attr_accessor :setupBlocks
					attr_accessor :teardownBlocks
				end
			}
			klass.methodCounter = 0
		end
		


		### Output the specified <tt>msgs</tt> joined together to
		### <tt>STDERR</tt> if <tt>$DEBUG</tt> is set.
		def self::debugMsg( *msgs )
			return unless $DEBUG
			self.message "DEBUG>>> %s" % msgs.join('')
		end

		### Output the specified <tt>msgs</tt> joined together to
		### <tt>STDOUT</tt>.
		def self::message( *msgs )
			$stderr.puts msgs.join('')
			$stderr.flush
		end


		### Add a setup block for the current testcase
		def self::addSetupBlock( &block )
			self.methodCounter += 1
			newMethodName = "setup_#{self.methodCounter}".intern
			define_method( newMethodName, &block )
			self.setupBlocks.push newMethodName
		end
			
		### Add a teardown block for the current testcase
		def self::addTeardownBlock( &block )
			self.methodCounter += 1
			newMethodName = "teardown_#{self.methodCounter}".intern
			define_method( newMethodName, &block )
			self.teardownBlocks.unshift newMethodName
		end
			

		#############################################################
		###	I N S T A N C E   M E T H O D S
		#############################################################

		### Forward-compatibility method for namechange in Test::Unit
		def setup( *args )
			self.class.setupBlocks.each {|sblock|
				debugMsg "Calling setup block method #{sblock}"
				self.send( sblock )
			}
			super( *args )
		end
		alias_method :set_up, :setup


		### Forward-compatibility method for namechange in Test::Unit
		def teardown( *args )
			super( *args )
			self.class.teardownBlocks.each {|tblock|
				debugMsg "Calling teardown block method #{tblock}"
				self.send( tblock )
			}
		end
		alias_method :tear_down, :teardown


		### Instance alias for the like-named class method.
		def message( *msgs )
			self.class.message( *msgs )
		end


		### Instance alias for the like-named class method
		def debugMsg( *msgs )
			self.class.debugMsg( *msgs )
		end


		### Output a separator line made up of <tt>length</tt> of the specified
		### <tt>char</tt>.
		def writeLine( length=75, char="-" )
			$stderr.puts "\r" + (char * length )
		end


		### Output a header for delimiting tests
		def printTestHeader( desc )
			return unless $VERBOSE || $DEBUG
			message ">>> %s <<<" % desc
		end


		### Try to force garbage collection to start.
		def collectGarbage
			a = []
			1000.times { a << {} }
			a = nil
			GC.start
		end


		### Output the name of the test as it's running if in verbose mode.
		def run( result )
			$stderr.puts self.name if $VERBOSE || $DEBUG
			super
		end


		#############################################################
		###	E X T R A   A S S E R T I O N S
		#############################################################

		### Negative of assert_respond_to
		def assert_not_respond_to( obj, meth )
			msg = "%s expected NOT to respond to '%s'" %
				[ obj.inspect, meth ]
			assert_block( msg ) {
				!obj.respond_to?( meth )
			}
		end


		### Assert that the instance variable specified by +sym+ of an +object+
		### is equal to the specified +value+. The '@' at the beginning of the
		### +sym+ will be prepended if not present.
		def assert_ivar_equal( value, object, sym )
			sym = "@#{sym}".intern unless /^@/ =~ sym.to_s
			msg = "Instance variable '%s'\n\tof <%s>\n\texpected to be <%s>\n" %
				[ sym, object.inspect, value.inspect ]
			msg += "\tbut was: <%s>" % object.instance_variable_get(sym)
			assert_block( msg ) {
				value == object.instance_variable_get(sym)
			}
		end


		### Assert that the specified +object+ has an instance variable which
		### matches the specified +sym+. The '@' at the beginning of the +sym+
		### will be prepended if not present.
		def assert_has_ivar( sym, object )
			sym = "@#{sym}" unless /^@/ =~ sym.to_s
			msg = "Object <%s> expected to have an instance variable <%s>" %
				[ object.inspect, sym ]
			assert_block( msg ) {
				object.instance_variables.include?( sym.to_s )
			}
		end

	end # class TestCase

end # module WordNet
