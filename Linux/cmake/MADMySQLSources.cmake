# The MADMySQL subset the Linux build compiles (MAD_LINUX.md §9): the 18
# implementation files of the Xcode target's 19.
#
# Excluded, with reason:
#   MADMySQLConnectionViewController.m  the connection form: a UIKit view
#                        controller, as §3's table says of the family
#
# It links the mysqlclient the image builds from the pin in
# Linux/libraries.conf, with openssl beneath it.  The licence position is
# unchanged by this: the GPL/FOSS-exception blocker and the MariaDB
# replacement are LICENSE_COMPLIANCE_PLAN.md's to settle, and nothing here
# ships (MAD_LINUX.md §7).
#
# Keep this list in step with MAD_LINUX.md §4.

set(MADMYSQL_SOURCES
	"${SOURCE_DIR}/MADDatabaseConnectionMySql.m"
	"${SOURCE_DIR}/MADDatabaseMySQL.m"
	"${SOURCE_DIR}/MADDataTypeMySQL.m"
	"${SOURCE_DIR}/MysqlCommitException.m"
	"${SOURCE_DIR}/MysqlConnection.m"
	"${SOURCE_DIR}/MysqlDelete.m"
	"${SOURCE_DIR}/MysqlException.m"
	"${SOURCE_DIR}/MysqlFetch.m"
	"${SOURCE_DIR}/MysqlFetch+DataTable.m"
	"${SOURCE_DIR}/MysqlFetchField.m"
	"${SOURCE_DIR}/MysqlIndex.m"
	"${SOURCE_DIR}/MysqlInsert.m"
	"${SOURCE_DIR}/MysqlLiteral.m"
	"${SOURCE_DIR}/MysqlRollbackException.m"
	"${SOURCE_DIR}/MysqlServer.m"
	"${SOURCE_DIR}/MysqlTruncate.m"
	"${SOURCE_DIR}/MysqlUpdate.m"
	"${SOURCE_DIR}/NSString+MysqlEscape.m"
)
