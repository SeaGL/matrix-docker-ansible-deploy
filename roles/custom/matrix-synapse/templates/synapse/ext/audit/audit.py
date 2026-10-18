import logging
from synapse.events import EventBase
from synapse.module_api.errors import SynapseError
from synapse.spam_checker_api import RegistrationBehaviour
from synapse.types import StateMap
from typing import Collection

logger = logging.getLogger(__name__)


class Audit:
    def __init__(self, config, api):
        self._api = api
        self._internal_domains = set(config["internal_domains"])
        self._room_alias = config["room_alias"]
        self._user_id = config["user_id"]

        self._api.register_spam_checker_callbacks(
            check_registration_for_spam=self.check_registration_for_spam,
        )
        self._api.register_third_party_rules_callbacks(
            on_new_event=self.on_new_event,
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

    async def on_new_event(self, event: EventBase, state_events: StateMap):
        if not (
            event.type == "m.room.member"
            and event.content.get("membership") == "join"
            and self._api.is_mine(event.sender)
            and not self._api.is_mine(event.room_id)
        ):
            return

        create_event = state_events.get(("m.room.create", ""))
        if create_event is None:
            logger.warning(
                "Failed to audit join of %s in %s: %s",
                event.sender,
                event.room_id,
                "m.room.create not yet available",
            )
            return

        if self._api.is_mine(create_event.sender):
            return

        domain = create_event.sender.split(":", 1)[1]
        if domain in self._internal_domains:
            return

        canonical_alias_event = state_events.get(("m.room.canonical_alias", ""))
        canonical_alias = canonical_alias_event.content.get("alias")
        if not canonical_alias:
            return

        await self.log(f"Off-homeserver: {event.sender} in {canonical_alias}")
