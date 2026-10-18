import logging
from synapse.module_api.errors import SynapseError

logger = logging.getLogger(__name__)


class Audit:
    def __init__(self, config, api):
        self._api = api
        self._room_alias = config["room_alias"]
        self._user_id = config["user_id"]

        self._api.register_account_validity_callbacks(
            on_user_registration=self.on_user_registration
        )

    async def on_user_registration(self, user_id):
        try:
            (room_id, _) = await self._api.lookup_room_alias(self._room_alias)

            await self._api.create_and_send_event_into_room(
                {
                    "sender": self._user_id,
                    "room_id": room_id,
                    "type": "m.room.message",
                    "content": {
                        "msgtype": "m.notice",
                        "body": f"User registration: {user_id}",
                    },
                }
            )
        except SynapseError as e:
            logger.error("Failed to report user registration %s: %s", user_id, e)
