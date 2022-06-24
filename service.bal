import ballerina/http;
import ballerinax/mysql;
import ballerina/sql;

# A service representing a network-accessible API
# bound to port `9090`.
service /donor on new http:Listener(9090) {

    # A resource for reading all aidPackages
    # + return - List of aidPackages and optionally filter by status
    resource function get AidPackages() returns json|error {
        string status="Draft";
        AidPackage[] aidPackages = [];
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            stream<AidPackage, error?> resultStream = dbClient->query(`SELECT PACKAGEID, NAME, DESCRIPTION, STATUS 
                                                                       FROM AID_PACKAGE
                                                                       WHERE STATUS!=${status};`);
            check from AidPackage aidPackage in resultStream
            do {
                aidPackage.aidPackageItems = [];
                aidPackages.push(aidPackage);
            };
            foreach AidPackage aidPackage in aidPackages {
                stream<AidPackageItem, error?> resultItemStream = dbClient->query(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID, NEEDID, QUANTITY, TOTALAMOUNT 
                                                                                   FROM AID_PACKAGE_ITEM
                                                                                   WHERE PACKAGEID=${aidPackage.packageID};`);
                check from AidPackageItem aidPackageItem in resultItemStream
                do {
                    aidPackage.aidPackageItems.push(aidPackageItem);
                };
            }

            error? e = dbClient.close();
            if e is error {
                return {"aidPackages": aidPackages}.toJson();
            }
        }
        return {"aidPackages": aidPackages}.toJson();
    }

    # A resource for fetching an aidPackage
    # + return - An aidPackage
    resource function get AidPackage(int packageID) returns json|error {
        AidPackage aidPackage = {};
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            aidPackage = check dbClient->queryRow(`SELECT PACKAGEID, NAME, DESCRIPTION, STATUS FROM AID_PACKAGE
                                                   WHERE PACKAGEID=${packageID};`);
            stream<AidPackageItem, error?> resultItemStream = dbClient->query(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID, NEEDID, QUANTITY, TOTALAMOUNT 
                                                                               FROM AID_PACKAGE_ITEM
                                                                               WHERE PACKAGEID=${packageID};`);
            aidPackage.aidPackageItems = [];
            check from AidPackageItem aidPackageItem in resultItemStream
            do {
                aidPackage.aidPackageItems.push(aidPackageItem);
            };
            error? e = dbClient.close();
            if e is error {
                return aidPackage.toJson();
            }
        }
        return aidPackage.toJson();
    }
}