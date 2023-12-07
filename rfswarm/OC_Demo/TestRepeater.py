from robot.api import SuiteVisitor
import time

class TestRepeater(SuiteVisitor):
	ROBOT_LISTENER_API_VERSION = 3

	testname = None
	count = 1

	def end_test(self, test, result):
		# print("test:", test)
		# print("test.parent:", test.parent)
		# print("test.parent.tests:", test.parent.tests)

		if self.count < 5:
			self.count += 1
			if self.testname is None:
				self.testname = test.name
			newname = "{} {}".format(self.testname, self.count)
			copy = test.copy(name=newname)
			test.parent.tests.append(copy)
			# test.parent.tests.append(test)

	def end_suite(self, suite, result):
		# This prevents the error:
		# [ ERROR ] Calling method 'end_suite' of listener 'TestRepeater.py' failed: TypeError: end_suite() takes 2 positional arguments but 3 were given
		pass

	def start_suite(self, suite, result):
		# This prevents the error:
		# [ ERROR ] Calling method 'start_suite' of listener 'TestRepeater.py' failed: TypeError: start_suite() takes 2 positional arguments but 3 were given
		pass

	def start_test(self, test, result):
		# This prevents the error:
		# [ ERROR ] Calling method 'start_test' of listener 'TestRepeater.py' failed: TypeError: start_test() takes 2 positional arguments but 3 were given
		pass
