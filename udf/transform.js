/**
 * User-Defined Function (UDF) for Cloud Run logs streaming to Datadog.
 * Implements redelivery / replay detection, unnesting, and delivery attempt
 * tracking as specified in the Google Cloud reference architecture:
 * https://docs.cloud.google.com/architecture/stream-logs-from-google-cloud-to-splunk
 * (adapted for Datadog intake).
 *
 * @param {string} inJson Raw incoming JSON string.
 * @return {string} Transformed JSON string for Datadog Logs intake.
 */
function process(inJson) {
  var obj;
  try {
    obj = JSON.parse(inJson);
  } catch (e) {
    // If not valid JSON, wrap raw text into a message object
    return JSON.stringify({
      message: inJson,
      ddsource: "cloud_run",
      delivery_attempt: 1
    });
  }

  var event;
  var redelivery = false;

  // If the message has already been converted to an event object with a
  // stringified obj.event JSON payload, or wrapped in obj.data by Pub/Sub,
  // then it's a replay of a previously failed delivery from the dead-letter queue.
  if (obj.event) {
    try {
      event = (typeof obj.event === "string") ? JSON.parse(obj.event) : obj.event;
      redelivery = true;
    } catch (e) {
      event = obj;
    }
  } else if (obj.data && typeof obj.data === "string") {
    try {
      event = JSON.parse(obj.data);
      redelivery = true;
    } catch (e) {
      event = obj;
    }
  } else {
    event = obj;
  }

  // Drop previously injected dead-letter attributes (such as errorMessage, status code)
  if (redelivery) {
    if (event.errorMessage) {
      delete event.errorMessage;
    }
    if (event.errorTimestamp) {
      delete event.errorTimestamp;
    }
    if (event.statusCode) {
      delete event.statusCode;
    }
  }

  // Keep a tally of delivery attempts for monitoring and alert verification in Datadog
  event.delivery_attempt = event.delivery_attempt || 1;
  if (redelivery) {
    event.delivery_attempt += 1;
    event.is_replayed = true;
  }

  // Standardize Datadog metadata attributes
  if (!event.ddsource) {
    event.ddsource = "cloud_run";
  }

  return JSON.stringify(event);
}