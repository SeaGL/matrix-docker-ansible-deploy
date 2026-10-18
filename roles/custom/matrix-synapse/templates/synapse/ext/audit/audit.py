import logging
from synapse.module_api.errors import SynapseError
from synapse.spam_checker_api import RegistrationBehaviour
from typing import Collection

logger = logging.getLogger(__name__)


class Audit:
    def __init__(self, config, api):
        self._api = api
        self._room_alias = config["room_alias"]
        self._user_id = config["user_id"]

        self._api.register_spam_checker_callbacks(
            check_registration_for_spam=self.check_registration_for_spam,
        )

    async def check_registration_for_spam(
        self,
        email_threepid: dict | None,
        username: str | None,
        request_info: Collection[tuple[str, str]],
        auth_provider_id: str | None = None,
    ) -> RegistrationBehaviour:
        name = self._api.get_qualified_user_id(username) if username else "[auto]"
        await self.log(f"User registration: {name}")

        return RegistrationBehaviour.ALLOW

    async def log(self, message: str):
        try:
            (room_id, _) = await self._api.lookup_room_alias(self._room_alias)

            await self._api.create_and_send_event_into_room(
                {
                    "sender": self._user_id,
                    "room_id": room_id,
                    "type": "m.room.message",
                    "content": {"msgtype": "m.notice", "body": message},
                }
            )
        except SynapseError as e:
            logger.error("Failed to log message “%s”: %s", message, e)
