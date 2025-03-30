import argparse
import json
import logging
import subprocess
from functools import partial
from pathlib import Path
from typing import Callable, Optional

import yaml


def evaluate(
    evaluator: Callable[[], subprocess.CompletedProcess],
) -> dict[str, dict[str, str]]:
    eval_process = evaluator()
    try:
        eval_process.check_returncode()
    except subprocess.CalledProcessError:
        logging.error(
            dict(
                eval_process_stdout=eval_process.stdout,
                eval_process_stderr=eval_process.stderr,
            )
        )
        raise

    workflows_json = eval_process.stdout
    workflows: dict[str, dict[str, str]] = json.loads(workflows_json)
    return workflows


def main(evaluated_ci_path: Optional[Path]):
    if evaluated_ci_path is None:
        eval_process = partial(
            subprocess.run,
            [
                "nix",
                "eval",
                "--option",
                "experimental-features",
                "nix-command flakes",
                ".#ci.workflows",
                "--json",
            ],
            text=True,
            capture_output=True,
        )
        workflows = evaluate(evaluator=eval_process)
    else:
        workflows = json.loads(evaluated_ci_path.read_text())

    for key, value in workflows.items():
        render_path = Path(key)
        render_path.parent.mkdir(exist_ok=True, parents=True)
        print(f"Writing to {render_path}")
        render_path.write_text(yaml.dump(value))


if __name__ == "__main__":
    argparser = argparse.ArgumentParser()
    argparser.add_argument("--evaluated-ci-path", required=False)
    args = argparser.parse_args()
    main(evaluated_ci_path=Path(args.evaluated_ci_path))
