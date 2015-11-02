/*
Can't change installation class so this functions as both.
*/

var COUNT_ID = "7lX8Qe2HC7"

Parse.Cloud.afterSave(Parse.Installation, function(request) {

  var installation = request.object;
  if (!installation.existed()) {
	   console.log("Installation doesn't already exist, verifying installation ref");
     // There's a bug where installation refs show as existed when they haven't associated data yet.  If the object is reading as new, we'll double check.
     var installationIsNew = function() {
       console.log("New installation ref");
       updateCountAndInstallationRef(request);
     }
     runIfInstallationIsNew(installation, installationIsNew);
  } else {
    console.log("Installation already exists: " + installation.id);
  }
});

function runIfInstallationIsNew(installation, installationIsNew) {
  Parse.Cloud.useMasterKey();
  console.log("Checking for existing installation ref " + installation.id);

  var InstallationRef = Parse.Object.extend("InstallationRef");
  var query = new Parse.Query(InstallationRef);
  query.equalTo("installationId", installation.id);

  var querySuccess = function(results) {
    console.log("Installation Ref Query Successful: " + results.length + " : " + results);
    if (results.length == 0) {
      console.log("Installation ref must be new");
      installationIsNew();
    } else {
      console.log("Installation ref already exists for installation: " + installation.id);
    }
  }
  var queryFailure = function(error) {
    console.log("Installation ref query failed: " + error.message);
  }

  query.find({
    success: querySuccess,
    error: queryFailure
  });
}

function updateCountAndInstallationRef(request) {
  Parse.Cloud.useMasterKey();
  var Counts = Parse.Object.extend("Counts");
  var query = new Parse.Query(Counts);
  query.get(COUNT_ID, { // Parse Installation Counter
    success: function(installationCount) {
      // The object was retrieved successfully.
      console.log("Found installation counter");
      installationCount.increment("count");
      installationCount.save(null, {
          success: function(count) {
            // Execute any logic that should take place after the object is saved.
            console.log("Installation count save successful")
          },
          error: function(count, error) {
            // Execute any logic that should take place if the save fails.
            // error is a Parse.Error with an error code and message.
            alert('COUNTER FAILED TO UPDATE!' + error.message);
          }
        });

      // Simple syntax to create a new subclass of Parse.Object.
      var InstallationRef = Parse.Object.extend("InstallationRef");
      var installationRef = new InstallationRef();

      var acl = new Parse.ACL();
      acl.setPublicReadAccess(false);
      acl.setPublicWriteAccess(false);
      installationRef.setACL(acl);

      installationRef.set("installationId", request.object.id);
      installationRef.set("appName", request.object.get("appName"));
      installationRef.save(null, {
          success: function(installationRefOb) {
            // Execute any logic that should take place after the object is saved.
            console.log("Installation ref successful")
          },
          error: function(installationRefOb, error) {
            // Execute any logic that should take place if the save fails.
            // error is a Parse.Error with an error code and message.
            alert('Failed to create new installationRef for refId' + request.object.objectId + ', with error code: ' + error.message);
          }
        });
    },
    error: function(object, error) {
      // The object was not retrieved successfully.
      // error is a Parse.Error with an error code and message.
      console.error("Error finding installation count!" + error.code + ": " + error.message);
    }
  });
}

/*
SEND RANDOM CHEER FUNCTIONALITY
*/

Parse.Cloud.define("sendRandomCheer", sendRandomCheer)

function sendRandomCheer(request, response) {
  Parse.Cloud.useMasterKey();

  var fromId = request.params.fromInstallationId;
  console.log("Cheer sent from Id: " + fromId);
  var isUserBanned = isIdBanned(fromId);
  if (isUserBanned) {
    console.log("Banned user attempted to send cheer: " + fromId);
    response.success("Whatever bro, Imma pretend you're doing something.");
  }

  var params = request.params;
  var from = params.fromName;
  var location = params.fromLocation;
  params.message = from + " sent you some Christmas cheer from " + location;

  var callback = function(success) {
    if (success) {
      response.success("SUCCESS");
    } else {
      response.error("FAILURE!");
    }
  };

  createAndSaveRandomCheerNotificationWithParamsAndCallback(params, function(newCheerNote) {
    if (exists(newCheerNote)) {
      var isResponse = false;
      sendPushForNewChristmasCheerNotificationWithCallback(newCheerNote, callback, isResponse);
    } else {
      callback(false);
    }
  });
}

function isIdBanned(id) {

  var bannedUsersIds = ["WHkuZ3S8AI"];
  // currently unused, just saving.
  var bannedApplicationIds = ["9ceb9ac2-4121-4aaf-b78b-4737bafbf714"];

  return contains(bannedUsersIds, id);
}

function contains(a, obj) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] === obj) {
      return true;
    }
  }
  return false;
}

/*
Create And Save Random CheerNotification
*/

function createAndSaveRandomCheerNotificationWithParamsAndCallback(params, callback) {

  var handler = function(randomInstallationRef) {
    console.log("Got installation " + randomInstallationRef);
    if (exists(randomInstallationRef)) {
      params.toInstallationId = randomInstallationRef.get("installationId");
      params.hasBeenRespondedTo = false;
      var newNote = newChristmasCheerNotificationWithParams(params);
      var failureFunction = function(newNote, error) {
        var failureMessage = "Failed to saved note from " + newNote.get("fromInstallationId") + " to " + newNote.get("toInstallationId") + " w/ error message: " + error.message;
        console.error(failureMessage);
        callback(null);
      };

      newNote.save(null, {
        success: callback,
        error: failureFunction
      });

    } else {
      callback(null);
    }
  };

  getRandomInstallationRefWithParamsAndCallback(params, handler);
}

/*
Send Push For Cheer Note
*/

function sendPushForNewChristmasCheerNotificationWithCallback(newCheerNote, callback, isResponse) {

  // Setup push query
  var pushQuery = new Parse.Query(Parse.Installation);
  pushQuery.equalTo("objectId", newCheerNote.get("toInstallationId"));

  var data = pushDataForNewCheerNote(newCheerNote, isResponse);

  var info = {
    where: pushQuery,
    data: data
  };

  var handler = {
    success: function() {
      callback(true);
    },
    error: function(error) {
      var fromInstallationId = newCheerNote.get("fromInstallationId");
      var toInstallationId = newCheerNote.get("toInstallationId");
      var failureMessage = "FAILURE to send push from installation id: " + fromInstallationId + " to id:" + toInstallationId;
      console.error(failureMessage);
      callback(false);
    }
  };

  Parse.Push.send(info, handler);

}

/*
Generate Push Data From Cheer Note
*/

function pushDataForNewCheerNote(newCheerNote, isResponse) {
  var randomTone = randomNotificationSound();
  var data = {
    fromUserId: newCheerNote.get("fromUserId"),
    fromInstallationId: newCheerNote.get("fromInstallationId"),
    fromName: newCheerNote.get("fromName"),
    fromLocation: newCheerNote.get("fromLocation"),
    toInstallationId: newCheerNote.get("toInstallationId"),
    isResponse: newCheerNote.get("isResponse"),
    originalNoteId: newCheerNote.id,
    badge: "Increment",
    title: "Merry Christmas!",
    sound: randomTone,
    alert: newCheerNote.get("message"),
    isResponse: isResponse === true
  };

  return data;
}

/*
Get Random Count
*/

function getRandomSkipWithCallback(callback) {

  var countsClassName = "Counts";

  var Counts = Parse.Object.extend(countsClassName);
  var countsQuery = new Parse.Query(Counts);

  var successFunction = function(installationCount) {
    var maxCount = installationCount.get("count");
    maxCount -= 1; // - 1 to omit current user from count
    var randomSkip = Math.floor(Math.random() * maxCount);
    callback(randomSkip);
  };
  var failureFunction = function(object, error) {
    var failureMessage = "Error finding installation count!" + error.code + ": " + error.message;
    console.error(failureMessage);
    callback(null);
  };

  countsQuery.get(COUNT_ID, { // Parse Installation Counter
    success: successFunction,
    error: failureFunction
  });
}

/*
Use Random Skip To Get Random Installation Ref
*/

function getRandomInstallationRefWithParamsAndCallback(params, callback) {
  getRandomSkipWithCallback(function(skip) {
    if (exists(skip)) {

      var installationRefClassName = "InstallationRef";
      var InstallationRef = Parse.Object.extend(installationRefClassName);

      var refQuery = new Parse.Query(InstallationRef);
      refQuery.notEqualTo("installationId", params.fromInstallationId);
      refQuery.ascending("createdAt");
      refQuery.skip(skip);
      refQuery.limit = 1;
      console.log("Skipping: " + skip);

      var failureFunction = function(error) {
        console.error("Unable to find object!");
        callback(null);
      };

      refQuery.first({
        success: callback,
        error: failureFunction
      });

    } else {
      console.error("Unable to find random skip!");
      callback(null);
    }
  });
}

/*
Christmas Cheer Creator
*/

function newChristmasCheerNotificationWithParams(params) {
  var christmasCheerNotificationClassName = "ChristmasCheerNotification";
  var ChristmasCheerNotification = Parse.Object.extend(christmasCheerNotificationClassName);

  var newChristmasCheerNotification = new ChristmasCheerNotification();
  newChristmasCheerNotification.set("fromUserId", params.fromUserId);
  newChristmasCheerNotification.set("fromName", params.fromName);
  newChristmasCheerNotification.set("fromInstallationId", params.fromInstallationId);
  newChristmasCheerNotification.set("fromLocation", params.fromLocation);
  newChristmasCheerNotification.set("toInstallationId", params.toInstallationId);
  newChristmasCheerNotification.set("hasBeenRespondedTo", params.hasBeenRespondedTo);
  newChristmasCheerNotification.set("message", params.message);
  newChristmasCheerNotification.setACL(readOnlyACL());
  return newChristmasCheerNotification;
}

/*
ACL Creator
*/

function readOnlyACL() {
  var acl = new Parse.ACL();
  acl.setPublicReadAccess(true);
  acl.setPublicWriteAccess(false);
}

/*
JavaScript Helpers
*/

function exists(ob) {
  return (ob !== null && ob !== undefined);
}

function randomNotificationSound() {
  var availableNotes = [
  "sleighbells.wav",
  "merry_christmas_darling.wav",
  "merry_christmas.mp3",
  "santa_laugh.wav"
  ];
  var randomIndex = Math.floor(Math.random() * availableNotes.length);
  var randomNote = availableNotes[randomIndex];
  return randomNote;
}

/*
RETURN CHEER FUNCTIONALITY
*/

Parse.Cloud.define("returnCheer", function(request, response) {

  Parse.Cloud.useMasterKey();
  var originalNoteId = request.params.originalNoteId;
  var ChristmasCheerNotification = Parse.Object.extend("ChristmasCheerNotification");
  var originalNoteQuery = new Parse.Query(ChristmasCheerNotification);
  originalNoteQuery.get(originalNoteId, {
    success: function(originalNote) {

      originalNote.set("hasBeenRespondedTo", true);
      originalNote.save(null, {
        success: function(originalNote) {
          var successMessage = "Succesfully updatedOriginalNote w/ Id " + originalNote.id;
          console.log(successMessage);

          var fromUserId = request.params.fromUserId;
          var fromInstallationId = request.params.fromInstallationId;
          var fromName = request.params.fromName;
          var fromLocation = request.params.fromLocation;
          var toInstallationId = originalNote.get("fromInstallationId")
          var message = fromName + " from " + fromLocation + " returned your Christmas cheer!";

          var ChristmasCheerNotification = Parse.Object.extend("ChristmasCheerNotification");
          var newChristmasCheerNotification = new ChristmasCheerNotification();
          newChristmasCheerNotification.set("fromUserId", fromUserId);
          newChristmasCheerNotification.set("fromName", fromName);
          newChristmasCheerNotification.set("fromInstallationId", fromInstallationId);
          newChristmasCheerNotification.set("fromLocation", fromLocation);
          newChristmasCheerNotification.set("toInstallationId", toInstallationId);
          newChristmasCheerNotification.set("hasBeenRespondedTo", true);
          newChristmasCheerNotification.set("initiationNoteId", originalNote.id);
          newChristmasCheerNotification.set("message", message);

          var acl = new Parse.ACL();
          acl.setPublicReadAccess(true);
          acl.setPublicWriteAccess(false);
          newChristmasCheerNotification.setACL(acl);

          newChristmasCheerNotification.save(null, {
            success: function(newNote) {
              var successMessage = "Succesfully saved response note from " + fromInstallationId + " to " + toInstallationId;
              console.log(successMessage);

              // Get random notification sound (iOS)
              var randomNote = randomNotificationSound();

              // Setup push query
              var pushQuery = new Parse.Query(Parse.Installation);
              pushQuery.equalTo("objectId", toInstallationId);
              // Send PUSH
              Parse.Push.send({
                where: pushQuery,
                data: {
                  fromUserId: fromUserId,
                  fromInstallationId: fromInstallationId,
                  fromName: fromName,
                  fromLocation: fromLocation,
                  toInstallationId: toInstallationId,
                  isResponse: true,
                  badge: "Increment",
                  title: "Merry Christmas!",
                  sound: randomNote,
                  alert: message,
                }
              }, {
                success: function() {
                  var successMessage = "Succesfully returned christmas cheer push from installation id: " + fromInstallationId + " to installationId:" + toInstallationId;
                  console.log(successMessage);
                  response.success(successMessage);
                },
                error: function(error) {
                  var failureMessage = "FAILURE to send push from installation id: " + fromInstallationId + " to id:" + toInstallationId + "for original note id: " + originalNote.id;
                  console.log(failureMessage);
                  response.error(failureMessage);
                }
              });
            },
            error: function(newNote, error) {
              var failureMessage = "Failed to saved note from " + fromInstallationId + " to " + toInstallationId + " w/ error message: " + error.message;
              response.error(failureMessage);(failureMessage);
              response.error(failureMessage);
            }
          });
        },
        error: function(originalNote, error) {
          var errorMessage = "FAILED to updatedOriginalNote w/ Id " + originalNote.id;
          console.error(errorMessage);
          response.error(errorMessage)
        }
      });

    },
    error: function(originalNote, error) {
      var errorMessage = "FAILED to retrieve original w/ Id " + originalNote.id;
      console.error(errorMessage);
      response.error(errorMessage)
    }
  });
});
