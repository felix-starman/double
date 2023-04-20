require Double
Double.defmock(TestMock, for: TestModule)
Double.defmock(TestMock2, for: TestModule)

# TODO - support for-keywords w/ defmock
# Double.defmock(ConfiguredMock, for: [process: 1, process: 3])

# TODO - support for-behaviour w/ defmock
# Double.defmock(BehavedMock, for: TestBehaviour)
